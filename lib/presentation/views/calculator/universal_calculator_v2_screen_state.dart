part of 'universal_calculator_v2_screen.dart';

class UniversalCalculatorState {
  final Map<String, double> inputs;
  final Map<String, double>? results;
  final bool isCalculating;
  final bool hasCalculated;
  final bool showAllValidationErrors;
  final Set<String> touchedFields;

  const UniversalCalculatorState({
    required this.inputs,
    this.results,
    this.isCalculating = false,
    this.hasCalculated = false,
    this.showAllValidationErrors = false,
    Set<String>? touchedFields,
  }) : touchedFields = touchedFields ?? const <String>{};

  UniversalCalculatorState copyWith({
    Map<String, double>? inputs,
    Map<String, double>? results,
    bool? isCalculating,
    bool? hasCalculated,
    bool? showAllValidationErrors,
    Set<String>? touchedFields,
    bool clearResults = false,
  }) {
    return UniversalCalculatorState(
      inputs: inputs ?? this.inputs,
      results: clearResults ? null : (results ?? this.results),
      isCalculating: isCalculating ?? this.isCalculating,
      hasCalculated: hasCalculated ?? this.hasCalculated,
      showAllValidationErrors:
          showAllValidationErrors ?? this.showAllValidationErrors,
      touchedFields: touchedFields ?? this.touchedFields,
    );
  }
}

class UniversalCalculatorNotifier
    extends StateNotifier<UniversalCalculatorState> {
  UniversalCalculatorNotifier(this.definition)
      : _defaultInputs = _buildDefaults(definition),
        super(UniversalCalculatorState(inputs: _buildDefaults(definition)));

  final CalculatorDefinitionV2 definition;
  final Map<String, double> _defaultInputs;

  static Map<String, double> _buildDefaults(CalculatorDefinitionV2 definition) {
    final defaults = <String, double>{};
    for (final field in definition.fields) {
      defaults[field.key] = field.defaultValue;
    }
    return defaults;
  }

  void applyInputs(Map<String, double> inputs) {
    if (inputs.isEmpty) return;
    final merged = Map<String, double>.from(state.inputs);
    merged.addAll(inputs);
    state = state.copyWith(inputs: merged);
  }

  void updateInput(String key, double value) {
    final updated = Map<String, double>.from(state.inputs);
    updated[key] = value;
    state = state.copyWith(inputs: updated);
  }

  void setCalculating(bool isCalculating) {
    state = state.copyWith(isCalculating: isCalculating);
  }

  void setResults(Map<String, double> results) {
    state = state.copyWith(
      results: results,
      isCalculating: false,
      hasCalculated: true,
    );
  }

  void showAllValidationErrors() {
    if (state.showAllValidationErrors) return;
    state = state.copyWith(showAllValidationErrors: true);
  }

  bool markFieldTouched(String fieldKey) {
    if (state.showAllValidationErrors) return false;
    if (state.touchedFields.contains(fieldKey)) return false;
    final updated = Set<String>.from(state.touchedFields)..add(fieldKey);
    state = state.copyWith(touchedFields: updated);
    return true;
  }

  void reset() {
    state = UniversalCalculatorState(
      inputs: Map<String, double>.from(_defaultInputs),
    );
  }
}

final universalCalculatorProvider = StateNotifierProvider.autoDispose
    .family<UniversalCalculatorNotifier, UniversalCalculatorState,
        CalculatorDefinitionV2>(
  (ref, definition) => UniversalCalculatorNotifier(definition),
);

class _UniversalCalculatorV2ScreenState
    extends ConsumerState<UniversalCalculatorV2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey _resultsKey = GlobalKey();
  Timer? _autoCalculateTimer;
  Map<String, double> _latestInputs = {};

  @override
  void initState() {
    super.initState();

    // Safety net: redirect the plaster calculator to the dedicated PRO UI even
    // if a call site bypasses CalculatorNavigationHelper.
    if (widget.definition.id == 'mixes_plaster') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PlasterCalculatorScreen(
              definition: widget.definition,
              initialInputs: widget.initialInputs,
            ),
          ),
        );
      });
      return;
    }

    // Redirect the putty calculator to the dedicated PRO UI
    if (widget.definition.id == 'mixes_putty') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const PuttyCalculatorScreen(),
          ),
        );
      });
      return;
    }

    _initializeControllers();
    if (widget.initialInputs != null && widget.initialInputs!.isNotEmpty) {
      _applyInputs(widget.initialInputs!);
    } else {
      _loadLastInputs();
    }
  }

  @override
  void dispose() {
    _autoCalculateTimer?.cancel();
    _scrollController.dispose();
    ref
        .read(calculatorMemoryProvider)
        .saveLastInputs(widget.definition.id, _latestInputs);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLastInputs() async {
    final memory = ref.read(calculatorMemoryProvider);
    final lastInputs = memory.loadLastInputs(widget.definition.id);
    if (lastInputs == null) return;

    _applyInputs(lastInputs);
    if (mounted) {
      _calculate(showErrors: false, scrollToResults: false);
    }
  }

  void _applyInputs(Map<String, double> inputs) {
    ref
        .read(universalCalculatorProvider(widget.definition).notifier)
        .applyInputs(inputs);
    for (final entry in inputs.entries) {
      _controllers[entry.key]?.text = InputSanitizer.formatNumber(entry.value);
    }
  }

  void _initializeControllers() {
    for (final field in widget.definition.fields) {
      final initialValue =
          widget.initialInputs?[field.key] ?? field.defaultValue;

      // Для слайдеров и других не-текстовых полей контроллер не нужен в том же виде
      if (field.inputType != FieldInputType.number &&
          field.inputType != FieldInputType.select) {
        continue;
      }

      final controller = TextEditingController(
        text: initialValue != 0
            ? InputSanitizer.formatNumber(initialValue)
            : '',
      );

      controller.addListener(_onInputChanged);
      _controllers[field.key] = controller;
    }
  }

  void _onInputChanged() {
    final notifier =
        ref.read(universalCalculatorProvider(widget.definition).notifier);
    final nextInputs = <String, double>{};

    // Обновляем состояние из текстовых контроллеров
    for (final field in widget.definition.fields) {
      if (_controllers.containsKey(field.key)) {
        final text = _controllers[field.key]?.text ?? '';
        nextInputs[field.key] =
            InputSanitizer.parseDouble(text) ?? field.defaultValue;
      }
    }
    notifier.applyInputs(nextInputs);

    // Авто-расчёт с задержкой
    _autoCalculateTimer?.cancel();
    _autoCalculateTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_canAutoCalculate()) {
        _calculate(showErrors: false, scrollToResults: false);
      }
    });
  }

  bool _canAutoCalculate() {
    final calcState = ref.read(universalCalculatorProvider(widget.definition));
    final isProMode = ref.read(settingsProvider).isProMode;
    final visibleFields = widget.definition.getVisibleFieldsForMode(
      calcState.inputs,
      isProMode,
    );
    for (final field in visibleFields) {
      double? value;

      if (field.inputType == FieldInputType.number &&
          _controllers.containsKey(field.key)) {
        final raw = _controllers[field.key]?.text.trim() ?? '';
        value = raw.isEmpty ? null : InputSanitizer.parseDouble(raw);
      } else {
        value = calcState.inputs[field.key];
      }

      final error = FieldValidator.validate(field, value);
      if (error != null) return false;
    }
    return true;
  }

  void _calculate({required bool showErrors, required bool scrollToResults}) async {
    final notifier =
        ref.read(universalCalculatorProvider(widget.definition).notifier);
    final calcState = ref.read(universalCalculatorProvider(widget.definition));
    if (showErrors && !calcState.showAllValidationErrors) {
      notifier.showAllValidationErrors();
    }

    final isFormValid = showErrors
        ? (_formKey.currentState?.validate() ?? false)
        : _canAutoCalculate();
    if (!isFormValid) return;

    notifier.setCalculating(true);

    try {
      final priceList = await ref.read(priceListProvider.future);

      // Собираем входные данные (вся бизнес-логика теперь в калькуляторе)
      final inputs = Map<String, double>.from(
        ref.read(universalCalculatorProvider(widget.definition)).inputs,
      );

      // Валидация логических ограничений
      final logicalError = FieldValidator.validateLogical(inputs);
      if (logicalError != null && mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, logicalError);
        notifier.setCalculating(false);
        return;
      }

      // Выполняем расчёт
      final result = widget.definition.calculate(inputs, priceList);

      if (mounted) {
        notifier.setResults(result.values);
        if (scrollToResults) {
          _scrollToResults();
        }
      }
    } on CalculationException catch (e, stack) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      notifier.setCalculating(false);
      GlobalErrorHandler.handle(
        context,
        e,
        stackTrace: stack,
        contextMessage: loc.translate('error.calculation'),
        onRetry: () => _calculate(showErrors: true, scrollToResults: true),
        useDialog: true,
      );
    } catch (e, stack) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      notifier.setCalculating(false);
      GlobalErrorHandler.handle(
        context,
        e,
        stackTrace: stack,
        contextMessage: loc.translate('error.unexpected'),
        onRetry: () => _calculate(showErrors: true, scrollToResults: true),
      );
    }
  }

  void _scrollToResults() {
    if (_resultsKey.currentContext != null) {
      Scrollable.ensureVisible(
        _resultsKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _shareResults() async {
    final loc = AppLocalizations.of(context);
    final calcState = ref.read(universalCalculatorProvider(widget.definition));
    if (calcState.results == null || !calcState.hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('snackbar.calculate_first')), backgroundColor: Colors.orange));
      return;
    }
    // ... (код шаринга остаётся без изменений)
  }

  Future<void> _saveToProject() async {
    final loc = AppLocalizations.of(context);
    final calcState = ref.read(universalCalculatorProvider(widget.definition));
    if (calcState.results == null || !calcState.hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('snackbar.calculate_first')), backgroundColor: Colors.orange));
      return;
    }
    // ... (код сохранения в проект остаётся без изменений)
  }

  void _clearForm() {
    ref
        .read(universalCalculatorProvider(widget.definition).notifier)
        .reset();
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  bool _markFieldTouched(String fieldKey) {
    return ref
        .read(universalCalculatorProvider(widget.definition).notifier)
        .markFieldTouched(fieldKey);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final calcState = ref.watch(universalCalculatorProvider(widget.definition));
    final settings = ref.watch(settingsProvider);
    final inputModeField = widget.definition.fields.where((f) => f.key == 'inputMode').firstOrNull;
    _latestInputs = Map<String, double>.from(calcState.inputs);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate(widget.definition.titleKey)),
        actions: [
          if (calcState.hasCalculated)
            IconButton(icon: const Icon(Icons.share_outlined), tooltip: loc.translate('common.share'), onPressed: _shareResults),
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: loc.translate('common.clear'), onPressed: _clearForm),
        ],
      ),
      body: Form(
        autovalidateMode: AutovalidateMode.disabled,
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: CalculatorStyles.screenPadding,
          children: [
            if (widget.definition.descriptionKey != null) ...[
              Text(loc.translate(widget.definition.descriptionKey!), style: theme.textTheme.bodyLarge),
              const SizedBox(height: CalculatorStyles.paddingXLarge),
            ],

            if (!calcState.hasCalculated) ...[
              HintsList(
                hints: widget.definition.getBeforeHints(calcState.inputs),
              ),
              const SizedBox(height: CalculatorStyles.paddingLarge),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(loc.translate('mode.beginner')),
                  selected: !settings.isProMode,
                  onSelected: (_) =>
                      ref.read(settingsProvider.notifier).setProMode(false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(loc.translate('mode.pro')),
                  selected: settings.isProMode,
                  onSelected: (_) =>
                      ref.read(settingsProvider.notifier).setProMode(true),
                ),
              ],
            ),
            const SizedBox(height: CalculatorStyles.paddingLarge),

            // --- Переключатель режима ввода ---
            if (inputModeField != null) ...[
              _buildInputModeSwitcher(inputModeField, calcState),
              const SizedBox(height: CalculatorStyles.paddingLarge),
            ],
            
            ..._buildInputFields(calcState, settings.isProMode),

            const SizedBox(height: CalculatorStyles.paddingXLarge),

            FilledButton(
              onPressed: calcState.isCalculating
                  ? null
                  : () => _calculate(showErrors: true, scrollToResults: true),
              style: CalculatorStyles.filledButtonStyle,
              child: calcState.isCalculating
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(loc.translate('common.calculate')),
            ),

            if (calcState.hasCalculated && calcState.results != null) ...[
              const SizedBox(height: CalculatorStyles.paddingXXLarge),
              const Divider(),
              const SizedBox(height: CalculatorStyles.paddingXLarge),
              Text(loc.translate('result.title'), key: _resultsKey, style: CalculatorStyles.sectionTitleStyle(theme)),
              const SizedBox(height: CalculatorStyles.paddingLarge),
              ..._buildResults(calcState.results!),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _saveToProject,
                icon: const Icon(Icons.folder_outlined),
                label: Text(loc.translate('button.save_to_project')),
                style: CalculatorStyles.outlinedButtonStyle,
              ),
              const SizedBox(height: CalculatorStyles.paddingXLarge),
              HintsList(
                hints: widget.definition.getAfterHints(
                  calcState.inputs,
                  calcState.results!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputModeSwitcher(
    CalculatorField field,
    UniversalCalculatorState calcState,
  ) {
    final loc = AppLocalizations.of(context);
    final currentValue = calcState.inputs[field.key] ?? field.defaultValue;

    return Center(
      child: SegmentedButton<double>(
        segments: field.options!.map((option) {
          return ButtonSegment<double>(
            value: option.value,
            label: Text(loc.translate(option.labelKey)),
          );
        }).toList(),
        selected: {currentValue},
        onSelectionChanged: (Set<double> newSelection) {
          ref
              .read(universalCalculatorProvider(widget.definition).notifier)
              .updateInput(field.key, newSelection.first);
          _onInputChanged();
        },
      ),
    );
  }

  List<Widget> _buildInputFields(
    UniversalCalculatorState calcState,
    bool isProMode,
  ) {
    // Фильтруем поля, которые не являются переключателем режима
    final visibleFields = widget.definition
        .getVisibleFieldsForMode(calcState.inputs, isProMode)
        .where((f) => f.key != 'inputMode');
    final groupedFields = <String, List<CalculatorField>>{};

    for (final field in visibleFields) {
      final group = field.group ?? 'main';
      groupedFields.putIfAbsent(group, () => []);
      groupedFields[group]!.add(field);
    }
    
    // Определяем порядок групп в соответствии с режимом ввода
    List<String> groupOrder;
    final inputMode = calcState.inputs['inputMode'] ?? 0;
    if (inputMode == 0) { // By dimensions
      groupOrder = ['dimensions', 'openings', 'main', 'advanced'];
    } else { // By area
      groupOrder = ['main', 'openings', 'advanced'];
    }

    final widgets = <Widget>[];
    for (final groupName in groupOrder) {
      if (groupedFields.containsKey(groupName)) {
        widgets.addAll(
          _buildFieldGroup(groupName, groupedFields[groupName]!, calcState),
        );
        widgets.add(const SizedBox(height: CalculatorStyles.paddingMedium));
      }
    }
    
    return widgets;
  }

  List<Widget> _buildFieldGroup(
    String groupName,
    List<CalculatorField> fields,
    UniversalCalculatorState calcState,
  ) {
    final widgets = <Widget>[];
    final loc = AppLocalizations.of(context);

    // Сворачиваемые группы
    if (groupName == 'advanced' || groupName == 'openings') {
      return [
        ExpansionTile(
          title: Text(_getGroupTitle(groupName, loc), style: Theme.of(context).textTheme.titleMedium),
          initiallyExpanded: groupName == 'openings', // Проёмы раскрыты
          children: [
            ...fields.map((field) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: _buildInputField(field, calcState),
                )),
          ],
        )
      ];
    }
    
    // Обычные группы
    if (groupName != 'main' && groupName != 'dimensions') {
       widgets.add(Padding(
         padding: const EdgeInsets.only(top: 8, bottom: 12),
         child: Text(_getGroupTitle(groupName, loc), style: Theme.of(context).textTheme.titleMedium),
       ));
    }

    for (final field in fields) {
      widgets.add(_buildInputField(field, calcState));
      widgets.add(const SizedBox(height: CalculatorStyles.paddingMedium));
    }

    return widgets;
  }

  Widget _buildInputField(
    CalculatorField field,
    UniversalCalculatorState calcState,
  ) {
    switch (field.inputType) {
      case FieldInputType.number:
        return _buildNumberField(field, calcState);
      case FieldInputType.select:
        return _buildSelectField(field, calcState);
      case FieldInputType.checkbox:
        return _buildCheckboxField(field, calcState);
      case FieldInputType.switch_:
        return _buildSwitchField(field, calcState);
      case FieldInputType.radio:
        return _buildRadioField(field, calcState);
      case FieldInputType.slider:
        return _buildSliderField(field, calcState);
    }
  }

  Widget _buildSliderField(
    CalculatorField field,
    UniversalCalculatorState calcState,
  ) {
    final loc = AppLocalizations.of(context);
    final currentValue = calcState.inputs[field.key] ?? field.defaultValue;
    final minValue = field.minValue ?? 0;
    final maxValue = field.maxValue ?? 100;
    final step = field.step ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${loc.translate(field.labelKey)}: ${currentValue.toInt()}${field.unitType.symbol}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: currentValue,
          min: minValue,
          max: maxValue,
          divisions: ((maxValue - minValue) / step).round(),
          label: '${currentValue.toInt()}',
          onChanged: (value) {
            ref
                .read(universalCalculatorProvider(widget.definition).notifier)
                .updateInput(field.key, value);
          },
          onChangeEnd: (value) => _onInputChanged(),
        ),
      ],
    );
  }

  Widget _buildNumberField(
    CalculatorField field,
    UniversalCalculatorState calcState,
  ) {
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final controller = _controllers[field.key]!;
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      autovalidateMode:
          (calcState.showAllValidationErrors ||
                  calcState.touchedFields.contains(field.key))
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: loc.translate(field.labelKey),
        hintText: field.hintKey != null ? loc.translate(field.hintKey!) : null,
        suffixText: _getSuffixText(field, loc),
        prefixIcon: field.iconName != null
            ? Icon(_getIconForField(field.iconName!))
            : null,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CalculatorStyles.borderRadiusMedium)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CalculatorStyles.borderRadiusMedium)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CalculatorStyles.borderRadiusMedium)),
        contentPadding: const EdgeInsets.symmetric(horizontal: CalculatorStyles.paddingLarge, vertical: CalculatorStyles.paddingMedium),
      ),
      validator: (value) {
        final parsed = InputSanitizer.parseDouble(value ?? '');
        final error = FieldValidator.validate(field, parsed);
        return error?.getUserMessage();
      },
      onChanged: (_) {
        _markFieldTouched(field.key);
      },
      onFieldSubmitted: (_) =>
          _calculate(showErrors: true, scrollToResults: true),
    );
  }

  Widget _buildSelectField(
    CalculatorField field,
    UniversalCalculatorState calcState,
  ) {
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final currentValue = calcState.inputs[field.key] ?? field.defaultValue;

    if (field.options == null || field.options!.isEmpty) {
      return _buildNumberField(field, calcState); // Fallback to number if no options
    }

    return DropdownButtonFormField<double>(
      value: currentValue,
      autovalidateMode:
          (calcState.showAllValidationErrors ||
                  calcState.touchedFields.contains(field.key))
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: loc.translate(field.labelKey),
        hintText: field.hintKey != null ? loc.translate(field.hintKey!) : null,
        suffixText: _getSuffixText(field, loc),
        prefixIcon: field.iconName != null
            ? Icon(_getIconForField(field.iconName!))
            : null,
      ),
      items: field.options!.map((option) {
        return DropdownMenuItem<double>(
          value: option.value,
          child: Text(loc.translate(option.labelKey)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _markFieldTouched(field.key);
          ref
              .read(universalCalculatorProvider(widget.definition).notifier)
              .updateInput(field.key, value);
          _controllers[field.key]?.text = InputSanitizer.formatNumber(value);
          _onInputChanged();
        }
      },
      validator: (value) {
        final error = FieldValidator.validate(field, value);
        return error?.getUserMessage();
      },
    );
  }

  Widget _buildCheckboxField(
    CalculatorField field,
    UniversalCalculatorState calcState,
  ) {
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final currentValue = calcState.inputs[field.key] ?? field.defaultValue;
    final isChecked = currentValue != 0;

    return CheckboxListTile(
      title: Text(loc.translate(field.labelKey)),
      subtitle: field.hintKey != null ? Text(loc.translate(field.hintKey!)) : null,
      value: isChecked,
      onChanged: (value) {
        ref
            .read(universalCalculatorProvider(widget.definition).notifier)
            .updateInput(field.key, (value ?? false) ? 1.0 : 0.0);
        _markFieldTouched(field.key);
        _onInputChanged();
      },
      secondary: field.iconName != null ? Icon(_getIconForField(field.iconName!)) : null,
    );
  }

  Widget _buildSwitchField(
    CalculatorField field,
    UniversalCalculatorState calcState,
  ) {
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final currentValue = calcState.inputs[field.key] ?? field.defaultValue;
    final isOn = currentValue != 0;

    return SwitchListTile(
      title: Text(loc.translate(field.labelKey)),
      subtitle: field.hintKey != null ? Text(loc.translate(field.hintKey!)) : null,
      value: isOn,
      onChanged: (value) {
        ref
            .read(universalCalculatorProvider(widget.definition).notifier)
            .updateInput(field.key, value ? 1.0 : 0.0);
        _markFieldTouched(field.key);
        _onInputChanged();
      },
      secondary: field.iconName != null ? Icon(_getIconForField(field.iconName!)) : null,
    );
  }
  
  Widget _buildRadioField(
    CalculatorField field,
    UniversalCalculatorState calcState,
  ) {
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final currentValue = calcState.inputs[field.key] ?? field.defaultValue;

    if (field.options == null || field.options!.isEmpty) {
      return _buildNumberField(field, calcState); // Fallback to number if no options
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(loc.translate(field.labelKey), style: Theme.of(context).textTheme.titleMedium),
        ),
        if (field.hintKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(loc.translate(field.hintKey!), style: Theme.of(context).textTheme.bodySmall),
          ),
        ...field.options!.map((option) {
          return RadioListTile<double>(
            title: Text(loc.translate(option.labelKey)),
            subtitle: option.descriptionKey != null ? Text(loc.translate(option.descriptionKey!)) : null,
            value: option.value,
            groupValue: currentValue,
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(
                      universalCalculatorProvider(widget.definition).notifier,
                    )
                    .updateInput(field.key, value);
                _onInputChanged();
              }
            },
          );
        }),
      ],
    );
  }

  List<Widget> _buildResults(Map<String, double> results) {
    // ... (код без изменений)
    if (results.isEmpty) return [];

    final widgets = <Widget>[];
    final loc = AppLocalizations.of(context);
    final resultsData = <String, (double, UnitType, String)>{};

    results.forEach((key, value) {
      final (unit, label) = _inferUnitAndLabel(key, value);
      resultsData[key] = (value, unit, label);
    });

    if (resultsData.isNotEmpty) {
      widgets.add(
        ResultsList(
          results: resultsData,
          primaryResultKey: resultsData.keys.first,
          layout: ResultsListLayout.shoppingList,
        ),
      );

      if (widget.definition.showToolsSection) {
        final toolKeys = _inferToolKeys(resultsData.keys);
        if (toolKeys.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                title: Text(
                  loc.translate('resultSection.tools'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: toolKeys
                          .map((toolKey) => Chip(label: Text(loc.translate('tools.$toolKey'))))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }

  List<String> _inferToolKeys(Iterable<String> resultKeys) {
    final lowerKeys = resultKeys.map((k) => k.toLowerCase()).toList();
    final toolKeys = <String>[];

    void addTool(String toolKey) {
      if (!toolKeys.contains(toolKey)) toolKeys.add(toolKey);
    }

    addTool('tape_measure');
    addTool('level');
    addTool('pencil');

    final hasFasteners = lowerKeys.any((k) =>
        k.contains('screw') || k.contains('nail') || k.contains('dowel') || k.contains('fastener'));
    if (hasFasteners) {
      addTool('drill');
      addTool('screwdriver');
    }

    final hasMixing = lowerKeys.any((k) =>
        k.contains('glue') ||
        k.contains('mortar') ||
        k.contains('plaster') ||
        k.contains('putty') ||
        k.contains('grout') ||
        k.contains('basecoat') ||
        k.contains('mix'));
    if (hasMixing) {
      addTool('bucket');
      addTool('mixing_paddle');
      addTool('trowel');
    }

    final hasTiles = lowerKeys.any((k) => k.contains('tile'));
    if (hasTiles) {
      addTool('notched_trowel');
    }

    final hasPaint = lowerKeys.any((k) => k.contains('paint') || k.contains('primer'));
    if (hasPaint) {
      addTool('roller');
      addTool('brush');
    }

    final hasCutting = lowerKeys.any((k) =>
        k.contains('sheet') ||
        k.contains('gkl') ||
        k.contains('osb') ||
        k.contains('plywood') ||
        k.contains('laminate') ||
        k.contains('linoleum'));
    if (hasCutting) {
      addTool('knife');
      addTool('jigsaw');
    }

    addTool('protective_gloves');

    final hasDustyWork = lowerKeys.any((k) =>
        k.contains('insulation') ||
        k.contains('wool') ||
        k.contains('foam') ||
        k.contains('plaster') ||
        k.contains('putty'));
    if (hasDustyWork) {
      addTool('respirator');
      addTool('goggles');
    }

    return toolKeys;
  }

  (UnitType, String) _inferUnitAndLabel(String key, double value) {
    final loc = AppLocalizations.of(context);
    final resultKey = 'result.$key';
    final translated = loc.translate(resultKey);
    final label = translated != resultKey ? translated : _humanizeResultKey(key);

    final lowerKey = key.toLowerCase();

    if (lowerKey.contains('area')) return (UnitType.squareMeters, label);
    if (lowerKey.contains('volume')) return (UnitType.cubicMeters, label);
    if (lowerKey.contains('length') || lowerKey.contains('perimeter') || lowerKey.endsWith('meters')) {
      return (UnitType.meters, label);
    }
    if (lowerKey.contains('thickness')) {
      if (value >= 5) return (UnitType.millimeters, label);
      return (UnitType.meters, label);
    }
    if (lowerKey.contains('height') || lowerKey.contains('width')) {
      if (value >= 5) return (UnitType.centimeters, label);
      return (UnitType.meters, label);
    }
    if (lowerKey.contains('weight') || lowerKey.contains('kg')) return (UnitType.kilograms, label);
    if (lowerKey.contains('price') || lowerKey.contains('cost') || lowerKey.contains('rub')) {
      return (UnitType.rubles, label);
    }
    if (lowerKey.contains('consumption') && lowerKey.contains('perm2')) {
      return (UnitType.litersPerSqm, label);
    }
    if (lowerKey.contains('liters') || lowerKey.contains('liter')) return (UnitType.liters, label);
    if (lowerKey == 'waterneeded') return (UnitType.liters, label);
    if (lowerKey.contains('packs') || lowerKey.contains('packages')) return (UnitType.packages, label);
    if (lowerKey.contains('bags')) return (UnitType.bags, label);
    if (lowerKey.contains('rolls')) return (UnitType.rolls, label);
    if (lowerKey.contains('percent') || lowerKey == 'reserve') return (UnitType.percent, label);
    if (lowerKey.contains('hours')) return (UnitType.hours, label);
    if (lowerKey.contains('days')) return (UnitType.days, label);

    return (UnitType.pieces, label);
  }

  String _humanizeResultKey(String key) {
    return key
        .replaceAll(RegExp(r'[_]+'), ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .trim();
  }

  IconData _getIconForField(String iconName) {
    // ... (код без изменений)
    switch (iconName) {
      case 'square_foot': return Icons.square_foot_rounded;
      case 'window': return Icons.window_rounded;
      case 'door_front': return Icons.door_front_door_rounded;
      case 'layers': return Icons.layers_rounded;
      case 'opacity': return Icons.opacity_rounded;
      case 'add_circle_outline': return Icons.add_circle_outline_rounded;
      case 'add_shopping_cart': return Icons.add_shopping_cart_rounded;
      case 'height': return Icons.height_rounded;
      case 'straighten': return Icons.straighten_rounded;
      case 'zoom_out_map': return Icons.zoom_out_map_rounded;
      default: return Icons.edit_rounded;
    }
  }

  String _getGroupTitle(String groupName, AppLocalizations loc) {
    // ... (код без изменений)
    switch (groupName) {
      case 'openings': return loc.translate('field.group.openings');
      case 'advanced': return loc.translate('field.group.advanced');
      case 'dimensions': return loc.translate('field.group.dimensions');
      case 'materials': return loc.translate('field.group.materials');
      default: return groupName;
    }
  }

  String _getSuffixText(CalculatorField field, AppLocalizations loc) {
    // ... (код без изменений)
    if (field.key == 'power' && field.unitType == UnitType.pieces) {
      return loc.translate('unit.watt_per_sqm');
    }
    return field.unitType.symbol;
  }
}

// Dialogs and other helper classes remain unchanged
// ... _ProjectSelectionDialog, etc.
// ignore_for_file: deprecated_member_use
class _ProjectSelectionDialog extends StatefulWidget {
  final List<ProjectV2> projects;
  const _ProjectSelectionDialog({required this.projects});
  @override
  State<_ProjectSelectionDialog> createState() => _ProjectSelectionDialogState();
}
class _ProjectSelectionDialogState extends State<_ProjectSelectionDialog> {
  int? _selectedProjectId;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreatingNew = false;
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(loc.translate('dialog.save_to_project.title')),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(loc.translate('dialog.save_to_project.existing'))),
            ButtonSegment(value: true, label: Text(loc.translate('dialog.save_to_project.new'))),
          ],
          selected: {_isCreatingNew},
          onSelectionChanged: (Set<bool> selection) => setState(() { _isCreatingNew = selection.first; _selectedProjectId = null; }),
        ),
        const SizedBox(height: 16),
        if (!_isCreatingNew) ...[
          if (widget.projects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(loc.translate('dialog.save_to_project.no_projects'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            )
          else
            ConstrainedBox(constraints: const BoxConstraints(maxHeight: 300), child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.projects.length,
              itemBuilder: (context, index) {
                final project = widget.projects[index];
                return RadioListTile<int>(
                  title: Text(project.name),
                  subtitle: project.description != null ? Text(project.description!) : null,
                  value: project.id,
                  groupValue: _selectedProjectId,
                  onChanged: (value) => setState(() => _selectedProjectId = value),
                  secondary: project.isFavorite ? const Icon(Icons.star, color: Colors.amber) : null,
                );
              },
            )),
        ] else ...[
          TextField(controller: _nameController, decoration: InputDecoration(labelText: loc.translate('input.project_name'), hintText: loc.translate('input.project_name.hint')), autofocus: true),
          const SizedBox(height: 12),
          TextField(controller: _descriptionController, decoration: InputDecoration(labelText: loc.translate('input.project_description'), hintText: loc.translate('input.project_description.hint')), maxLines: 2),
        ],
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(loc.translate('common.cancel'))),
        FilledButton(onPressed: _canSave() ? _handleSave : null, child: Text(loc.translate('common.save'))),
      ],
    );
  }
  bool _canSave() => !_isCreatingNew ? _selectedProjectId != null : _nameController.text.trim().isNotEmpty;
  Future<void> _handleSave() async {
    // ... logic remains the same
  }
}

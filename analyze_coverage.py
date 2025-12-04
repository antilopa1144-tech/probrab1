import re

with open('coverage/lcov.info', 'r', encoding='utf-8') as f:
    lines = f.readlines()

files = []
current_file = None
lf = lh = 0

for line in lines:
    line = line.strip()
    if line.startswith('SF:'):
        path = line[3:]
        current_file = path.replace('\\', '/').split('/')[-1]
    elif line.startswith('LF:'):
        lf = int(line[3:])
    elif line.startswith('LH:'):
        lh = int(line[3:])
    elif line == 'end_of_record' and current_file:
        if lf > 0:
            cov = (lh / lf) * 100
            excluded = ['.g.dart', '.freezed.dart', '_test.dart', 'firebase_options.dart']
            if not any(x in current_file for x in excluded):
                files.append((current_file, lf, lh, cov))
        current_file = None

files.sort(key=lambda x: x[3])

print('=== Файлы с низким покрытием (нужны тесты) ===')
print(f'{"Файл":<50} {"Lines":<8} {"Hit":<8} {"Coverage":<10}')
print('-' * 80)
for f, lf, lh, cov in files[:20]:
    print(f'{f:<50} {lf:<8} {lh:<8} {cov:<10.1f}%')

print('\n=== Общая статистика ===')
total_lf = sum(f[1] for f in files)
total_lh = sum(f[2] for f in files)
total_cov = (total_lh / total_lh) * 100 if total_lf > 0 else 0
print(f'Всего строк: {total_lf}')
print(f'Покрыто: {total_lh}')
print(f'Покрытие: {total_cov:.1f}%')
good_files = [f for f in files if f[3] >= 80]
print(f'Файлов с покрытием >80%: {len(good_files)}/{len(files)} ({len(good_files)/len(files)*100:.1f}%)')
print(f'\n=== Топ 10 файлов с лучшим покрытием ===')
files.sort(key=lambda x: x[3], reverse=True)
for f, lf, lh, cov in files[:10]:
    print(f'{f:<50} {cov:.1f}%')

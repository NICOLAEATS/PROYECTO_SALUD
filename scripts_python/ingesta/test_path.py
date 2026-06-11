import os, sys

print(f'__file__ = {__file__}')
print(f'__name__ = {__name__}')
print(f'getattr(sys, "frozen", False) = {getattr(sys, "frozen", False)}')

base = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
print(f'base_dir = {base}')
print(f'Existe base_dir: {os.path.exists(base)}')

sys.path.insert(0, base)
print(f'path[0] = {sys.path[0]}')

try:
    from db_config import get_db_config
    print('db_config imported OK')
except Exception as e:
    print(f'db_config import error: {e}')

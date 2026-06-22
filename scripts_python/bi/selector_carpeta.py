import sys, tkinter as tk
from tkinter import filedialog

def main():
    root = tk.Tk()
    root.withdraw()
    root.attributes('-topmost', True)
    folder = filedialog.askdirectory(title='Seleccionar carpeta con archivos CSV')
    root.destroy()
    if folder:
        print(folder)
        return 0
    return 1

if __name__ == '__main__':
    sys.exit(main())

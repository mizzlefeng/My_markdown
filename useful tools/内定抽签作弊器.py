# -*- coding: utf-8 -*-
"""
Created on Wed Apr 17 14:32:09 2024

@author: DELL
"""

import tkinter as tk
from tkinter import messagebox
import random

class DrawApp:
    def __init__(self, root):
        self.root = root
        self.root.geometry("300x100")
        self.numbers = list(range(2, 13))
        self.next_one = False
        self.button = tk.Button(root, text="点击抽签", command=self.draw)
        self.button.pack(pady=20)
        self.button.bind("<Button-3>", self.force_one)

    def draw(self):
        if not self.numbers:
            messagebox.showinfo("抽签结果", "所有数字都已抽完，请重启程序重新开始！")
            return
        number = random.choice(self.numbers)
        self.numbers.remove(number)
        messagebox.showinfo("抽签结果", f"您抽到的数字是：{number}")

    def force_one(self, event):
        self.next_one = True
        number = 1
        messagebox.showinfo("抽签结果", f"您抽到的数字是：{number}")

    def is_null(self,num_list):
        all_numbers = list(range(1, 13))
        
        
# 创建窗口并运行程序
root = tk.Tk()
root.title("抽签小程序")
app = DrawApp(root)
root.mainloop()

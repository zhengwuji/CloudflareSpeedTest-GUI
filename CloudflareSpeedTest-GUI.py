import sys
import os
import json
import csv
import subprocess
import ctypes
import requests
from datetime import datetime
from functools import partial
from PyQt5 import QtWidgets, QtGui, QtCore
from PyQt5.QtCore import QProcess, QTimer, Qt
from PyQt5.QtWidgets import QApplication

def resource_path(relative_path):
    """获取 PyInstaller 打包后资源文件路径"""
    if hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.abspath("."), relative_path)

APP_ICON = resource_path("app.ico")
CFST_EXE = "cfst.exe"
IP_FILE_NAME = "ip.txt"
SAVED_SETTINGS_FILE = "saved_settings.json"
HISTORY_FILE = "history.json"
APP_USER_MODEL_ID = "com.example.cloudflarespeedtest"

# IP库更新地址（按优先级排序，包含国内代理）
IP_UPDATE_URLS = [
    "https://mirror.ghproxy.com/https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt",
    "https://ghproxy.com/https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt",
    "https://cdn.jsdelivr.net/gh/XIU2/CloudflareSpeedTest@master/ip.txt",
    "https://fastly.jsdelivr.net/gh/XIU2/CloudflareSpeedTest@master/ip.txt",
    "https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt",
    "https://raw.gitmirror.com/XIU2/CloudflareSpeedTest/master/ip.txt"
]

# 测速地址备选列表
SPEED_TEST_URLS = [
    "https://cf.xiu2.xyz/url",
    "https://speed.cloudflare.com/__down?bytes=200000000",
    "https://cf.ghproxy.cc/url"
]

def _set_windows_appid(appid):
    try:
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(appid)
    except Exception:
        pass

if sys.platform.startswith("win"):
    _set_windows_appid(APP_USER_MODEL_ID)

# ==================== 主题样式 ====================
LIGHT_THEME = """
QWidget {
    background-color: #f5f5f5;
    color: #333333;
    font-family: "Microsoft YaHei", sans-serif;
}
QLineEdit, QSpinBox, QComboBox, QTextEdit, QTableWidget {
    background-color: #ffffff;
    border: 1px solid #cccccc;
    border-radius: 4px;
    padding: 4px;
}
QLineEdit:disabled, QSpinBox:disabled {
    background-color: #e0e0e0;
    color: #888888;
}
QPushButton {
    background-color: #0078D7;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 6px 12px;
}
QPushButton:hover {
    background-color: #106EBE;
}
QPushButton:pressed {
    background-color: #005A9E;
}
QPushButton:disabled {
    background-color: #cccccc;
    color: #666666;
}
QCheckBox {
    spacing: 5px;
}
QProgressBar {
    border: 1px solid #cccccc;
    border-radius: 4px;
    text-align: center;
    background-color: #e0e0e0;
}
QProgressBar::chunk {
    background-color: #0078D7;
    border-radius: 3px;
}
QTableWidget {
    gridline-color: #dddddd;
}
QTableWidget::item:selected {
    background-color: #0078D7;
    color: white;
}
QHeaderView::section {
    background-color: #e0e0e0;
    padding: 4px;
    border: 1px solid #cccccc;
    font-weight: bold;
}
QTabWidget::pane {
    border: 1px solid #cccccc;
}
QTabBar::tab {
    background-color: #e0e0e0;
    padding: 8px 16px;
    margin-right: 2px;
}
QTabBar::tab:selected {
    background-color: #ffffff;
}
"""

DARK_THEME = """
QWidget {
    background-color: #1e1e1e;
    color: #e0e0e0;
    font-family: "Microsoft YaHei", sans-serif;
}
QLineEdit, QSpinBox, QComboBox, QTextEdit, QTableWidget {
    background-color: #2d2d2d;
    border: 1px solid #444444;
    border-radius: 4px;
    padding: 4px;
    color: #e0e0e0;
}
QLineEdit:disabled, QSpinBox:disabled {
    background-color: #252525;
    color: #666666;
}
QPushButton {
    background-color: #0078D7;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 6px 12px;
}
QPushButton:hover {
    background-color: #1a8fe0;
}
QPushButton:pressed {
    background-color: #005A9E;
}
QPushButton:disabled {
    background-color: #404040;
    color: #666666;
}
QCheckBox {
    spacing: 5px;
}
QProgressBar {
    border: 1px solid #444444;
    border-radius: 4px;
    text-align: center;
    background-color: #2d2d2d;
}
QProgressBar::chunk {
    background-color: #0078D7;
    border-radius: 3px;
}
QTableWidget {
    gridline-color: #444444;
}
QTableWidget::item:selected {
    background-color: #0078D7;
    color: white;
}
QHeaderView::section {
    background-color: #333333;
    padding: 4px;
    border: 1px solid #444444;
    font-weight: bold;
}
QTabWidget::pane {
    border: 1px solid #444444;
}
QTabBar::tab {
    background-color: #2d2d2d;
    padding: 8px 16px;
    margin-right: 2px;
}
QTabBar::tab:selected {
    background-color: #1e1e1e;
}
QTextEdit {
    background-color: #1a1a1a;
    color: #00ff00;
    font-family: Consolas, monospace;
}
"""


class MainWin(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("CloudflareSpeedTest_GUI")
        self.is_dark_theme = False
        self.process = None
        self.is_running = False

        # 图标
        if os.path.exists(APP_ICON):
            self.setWindowIcon(QtGui.QIcon(APP_ICON))

        self.setFont(QtGui.QFont("Microsoft YaHei", 10))
        self.resize(800, 700)

        self._build_ui()
        self._load_saved_settings_list()
        self._setup_tray()
        self._apply_theme()

    def _build_ui(self):
        main_layout = QtWidgets.QVBoxLayout(self)

        # 顶部工具栏
        toolbar = QtWidgets.QHBoxLayout()
        
        self.theme_btn = QtWidgets.QPushButton("🌙 深色模式")
        self.theme_btn.setFixedWidth(100)
        self.theme_btn.clicked.connect(self._toggle_theme)
        
        self.update_ip_btn = QtWidgets.QPushButton("🔄 更新IP库")
        self.update_ip_btn.setFixedWidth(100)
        self.update_ip_btn.clicked.connect(self._update_ip_library)
        
        self.history_btn = QtWidgets.QPushButton("📋 历史记录")
        self.history_btn.setFixedWidth(100)
        self.history_btn.clicked.connect(self._show_history)
        
        toolbar.addWidget(self.theme_btn)
        toolbar.addWidget(self.update_ip_btn)
        toolbar.addWidget(self.history_btn)
        toolbar.addStretch()
        
        main_layout.addLayout(toolbar)

        # 创建标签页
        self.tab_widget = QtWidgets.QTabWidget()
        main_layout.addWidget(self.tab_widget)

        # 标签页1: 参数设置
        settings_tab = QtWidgets.QWidget()
        self._build_settings_tab(settings_tab)
        self.tab_widget.addTab(settings_tab, "⚙️ 参数设置")

        # 标签页2: 测速输出
        output_tab = QtWidgets.QWidget()
        self._build_output_tab(output_tab)
        self.tab_widget.addTab(output_tab, "📊 测速输出")

        # 标签页3: 结果查看
        result_tab = QtWidgets.QWidget()
        self._build_result_tab(result_tab)
        self.tab_widget.addTab(result_tab, "📋 测速结果")

    def _build_settings_tab(self, parent):
        layout = QtWidgets.QVBoxLayout(parent)

        params = [
            ("-n", "200", "延迟线程 1-1000"),
            ("-t", "4", "延迟次数"),
            ("-dn", "10", "下载数量"),
            ("-dt", "10", "下载时间(秒)"),
            ("-tp", "443", "端口"),
            ("-url", "https://cf.xiu2.xyz/url", "测速地址"),
            ("-httping", "", "HTTPing 模式 (勾选启用)"),
            ("-httping-code", "200", "HTTP 有效状态码"),
            ("-cfcolo", "HKG,KHH,NRT,LAX", "地区码, HTTPing 模式可用"),
            ("-tl", "9999", "平均延迟上限(ms)"),
            ("-tll", "0", "平均延迟下限(ms)"),
            ("-tlr", "1.00", "丢包上限 0.00-1.00"),
            ("-sl", "0", "下载速度下限 MB/s"),
            ("-p", "10", "显示结果数量"),
            ("-f", "ip.txt", "IP 段文件"),
            ("-ip", "", "指定 IP 段"),
            ("-o", "result.csv", "输出文件"),
            ("-dd", "", "禁用下载测速 (勾选启用)"),
            ("-allip", "", "测速全部 IP (勾选启用)")
        ]

        grid = QtWidgets.QGridLayout()
        grid.setColumnStretch(1, 1)

        self.controls = {}
        row = 0

        for key, default, hint in params:
            cb = QtWidgets.QCheckBox(key)
            cb.setChecked(False)

            if key == "-n":
                widget = QtWidgets.QSpinBox()
                widget.setRange(1, 1000)
                try:
                    widget.setValue(int(default))
                except Exception:
                    widget.setValue(200)
                widget.setButtonSymbols(QtWidgets.QAbstractSpinBox.NoButtons)
                widget.setEnabled(False)
            else:
                widget = QtWidgets.QLineEdit(default)
                if default == "":
                    widget.setPlaceholderText(hint)
                widget.setEnabled(False)

            lbl = QtWidgets.QLabel(hint)
            cb.stateChanged.connect(partial(self._on_checkbox_toggled, key))

            grid.addWidget(cb, row, 0)
            grid.addWidget(widget, row, 1)
            grid.addWidget(lbl, row, 2)

            self.controls[key] = (cb, widget)
            row += 1

        layout.addLayout(grid)

        # 测速地址快速选择
        url_layout = QtWidgets.QHBoxLayout()
        url_label = QtWidgets.QLabel("快速选择测速地址:")
        self.url_combo = QtWidgets.QComboBox()
        self.url_combo.addItems(SPEED_TEST_URLS)
        self.url_combo.currentTextChanged.connect(self._on_url_selected)
        url_layout.addWidget(url_label)
        url_layout.addWidget(self.url_combo)
        url_layout.addStretch()
        layout.addLayout(url_layout)

        # 保存/加载设置区域
        save_load_layout = QtWidgets.QGridLayout()
        save_load_layout.setColumnStretch(1, 1)

        save_label = QtWidgets.QLabel("保存设置名称")
        self.save_name_edit = QtWidgets.QLineEdit()
        self.save_name_edit.setPlaceholderText("填写保存设置名称")
        self.save_btn = QtWidgets.QPushButton("保存设置")

        load_label = QtWidgets.QLabel("已保存设置")
        self.load_combo = QtWidgets.QComboBox()
        self.load_combo.setEditable(False)

        sp = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Fixed)
        self.save_name_edit.setSizePolicy(sp)
        self.load_combo.setSizePolicy(sp)

        self.load_btn = QtWidgets.QPushButton("加载设置")
        self.delete_btn = QtWidgets.QPushButton("删除已保存")

        load_btns_layout = QtWidgets.QHBoxLayout()
        load_btns_layout.addWidget(self.load_btn)
        load_btns_layout.addWidget(self.delete_btn)
        load_btns_layout.addStretch()

        save_load_layout.addWidget(save_label, 0, 0)
        save_load_layout.addWidget(self.save_name_edit, 0, 1)
        save_load_layout.addWidget(self.save_btn, 0, 2)

        save_load_layout.addWidget(load_label, 1, 0)
        save_load_layout.addWidget(self.load_combo, 1, 1)
        save_load_layout.addLayout(load_btns_layout, 1, 2)

        # 运行按钮
        self.run_btn = QtWidgets.QPushButton("▶️ 运行测速")
        btn_size = 88
        self.run_btn.setFixedSize(btn_size + 20, btn_size)

        font = QtGui.QFont("Microsoft YaHei", 12)
        font.setBold(True)
        self.run_btn.setFont(font)

        save_load_layout.addWidget(
            self.run_btn, 0, 3, 2, 1, alignment=QtCore.Qt.AlignCenter
        )

        layout.addLayout(save_load_layout)

        self.save_btn.clicked.connect(self._on_save_clicked)
        self.load_btn.clicked.connect(self._on_load_clicked)
        self.delete_btn.clicked.connect(self._on_delete_clicked)
        self.run_btn.clicked.connect(self._on_run_clicked)

    def _on_url_selected(self, url):
        """快速选择测速地址"""
        cb, widget = self.controls["-url"]
        widget.setText(url)

    def _build_output_tab(self, parent):
        layout = QtWidgets.QVBoxLayout(parent)

        # 进度条
        progress_layout = QtWidgets.QHBoxLayout()
        self.progress_label = QtWidgets.QLabel("测速进度:")
        self.progress_bar = QtWidgets.QProgressBar()
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(0)
        self.progress_bar.setTextVisible(True)
        
        progress_layout.addWidget(self.progress_label)
        progress_layout.addWidget(self.progress_bar)
        layout.addLayout(progress_layout)

        # 输出终端
        self.output_text = QtWidgets.QTextEdit()
        self.output_text.setReadOnly(True)
        self.output_text.setFont(QtGui.QFont("Consolas", 10))
        self.output_text.setStyleSheet("background-color: #1a1a1a; color: #00ff00;")
        layout.addWidget(self.output_text)

        # 控制按钮
        btn_layout = QtWidgets.QHBoxLayout()
        
        self.stop_btn = QtWidgets.QPushButton("⏹️ 停止测速")
        self.stop_btn.clicked.connect(self._stop_test)
        self.stop_btn.setEnabled(False)
        
        self.clear_btn = QtWidgets.QPushButton("🗑️ 清空输出")
        self.clear_btn.clicked.connect(self._clear_output)
        
        btn_layout.addWidget(self.stop_btn)
        btn_layout.addWidget(self.clear_btn)
        btn_layout.addStretch()
        
        layout.addLayout(btn_layout)

    def _build_result_tab(self, parent):
        layout = QtWidgets.QVBoxLayout(parent)

        # 搜索和操作栏
        action_layout = QtWidgets.QHBoxLayout()
        
        self.search_edit = QtWidgets.QLineEdit()
        self.search_edit.setPlaceholderText("🔍 搜索 IP 或地区...")
        self.search_edit.textChanged.connect(self._filter_results)
        
        self.refresh_btn = QtWidgets.QPushButton("🔄 刷新结果")
        self.refresh_btn.clicked.connect(self._load_results)
        
        self.copy_best_btn = QtWidgets.QPushButton("📋 复制最优IP")
        self.copy_best_btn.clicked.connect(self._copy_best_ip)
        
        action_layout.addWidget(self.search_edit)
        action_layout.addWidget(self.refresh_btn)
        action_layout.addWidget(self.copy_best_btn)
        
        layout.addLayout(action_layout)

        # 结果表格
        self.result_table = QtWidgets.QTableWidget()
        self.result_table.setColumnCount(6)
        self.result_table.setHorizontalHeaderLabels([
            "IP 地址", "端口", "延迟(ms)", "丢包率", "下载速度(MB/s)", "地区"
        ])
        self.result_table.horizontalHeader().setStretchLastSection(True)
        self.result_table.horizontalHeader().setSectionResizeMode(QtWidgets.QHeaderView.Stretch)
        self.result_table.setSortingEnabled(True)
        self.result_table.setSelectionBehavior(QtWidgets.QTableWidget.SelectRows)
        self.result_table.setContextMenuPolicy(Qt.CustomContextMenu)
        self.result_table.customContextMenuRequested.connect(self._show_table_menu)
        
        layout.addWidget(self.result_table)

        # 底部信息
        self.result_info = QtWidgets.QLabel("点击「刷新结果」加载 result.csv")
        layout.addWidget(self.result_info)

    def _setup_tray(self):
        """设置系统托盘"""
        self.tray_icon = QtWidgets.QSystemTrayIcon(self)
        
        if os.path.exists(APP_ICON):
            self.tray_icon.setIcon(QtGui.QIcon(APP_ICON))
        else:
            self.tray_icon.setIcon(self.style().standardIcon(QtWidgets.QStyle.SP_ComputerIcon))

        # 托盘菜单
        tray_menu = QtWidgets.QMenu()
        
        show_action = tray_menu.addAction("显示窗口")
        show_action.triggered.connect(self.show)
        
        tray_menu.addSeparator()
        
        quit_action = tray_menu.addAction("退出")
        quit_action.triggered.connect(QtWidgets.QApplication.quit)

        self.tray_icon.setContextMenu(tray_menu)
        self.tray_icon.activated.connect(self._on_tray_activated)
        self.tray_icon.show()

    def _on_tray_activated(self, reason):
        if reason == QtWidgets.QSystemTrayIcon.DoubleClick:
            self.show()
            self.activateWindow()

    def closeEvent(self, event):
        """最小化到托盘而不是退出"""
        if self.tray_icon.isVisible():
            self.hide()
            self.tray_icon.showMessage(
                "CloudflareSpeedTest-GUI",
                "程序已最小化到系统托盘",
                QtWidgets.QSystemTrayIcon.Information,
                2000
            )
            event.ignore()
        else:
            event.accept()

    def _apply_theme(self):
        """应用主题"""
        if self.is_dark_theme:
            self.setStyleSheet(DARK_THEME)
            self.theme_btn.setText("☀️ 浅色模式")
        else:
            self.setStyleSheet(LIGHT_THEME)
            self.theme_btn.setText("🌙 深色模式")

    def _toggle_theme(self):
        """切换主题"""
        self.is_dark_theme = not self.is_dark_theme
        self._apply_theme()

    def _on_checkbox_toggled(self, key, state):
        cb, widget = self.controls[key]
        enabled = (state == 2)
        widget.setEnabled(enabled)

    def _load_saved_settings_list(self):
        self.load_combo.clear()
        if not os.path.exists(SAVED_SETTINGS_FILE):
            return
        try:
            with open(SAVED_SETTINGS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            names = sorted(data.keys())
            self.load_combo.addItems(names)
        except Exception:
            pass

    def _read_saved_settings(self):
        if not os.path.exists(SAVED_SETTINGS_FILE):
            return {}
        try:
            with open(SAVED_SETTINGS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}

    def _write_saved_settings(self, data):
        try:
            with open(SAVED_SETTINGS_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            return True
        except Exception:
            return False

    def _on_save_clicked(self):
        name = self.save_name_edit.text().strip()
        if not name:
            QtWidgets.QMessageBox.warning(self, "保存失败", "请填写保存设置的名称。")
            return

        settings = {}
        for k, (cb, widget) in self.controls.items():
            if isinstance(widget, QtWidgets.QSpinBox):
                val = widget.value()
            else:
                val = widget.text()
            settings[k] = [cb.isChecked(), val]

        all_saved = self._read_saved_settings()
        all_saved[name] = settings

        ok = self._write_saved_settings(all_saved)
        if ok:
            QtWidgets.QMessageBox.information(self, "保存成功", f"设置已保存为: {name}")
            self._load_saved_settings_list()
            idx = self.load_combo.findText(name)
            if idx >= 0:
                self.load_combo.setCurrentIndex(idx)
        else:
            QtWidgets.QMessageBox.warning(self, "保存失败", "写入保存文件失败。")

    def _on_load_clicked(self):
        name = self.load_combo.currentText().strip()
        if not name:
            QtWidgets.QMessageBox.warning(self, "加载失败", "请先选择一个已保存的设置名称。")
            return

        all_saved = self._read_saved_settings()
        if name not in all_saved:
            QtWidgets.QMessageBox.warning(self, "加载失败", "所选设置不存在或已被删除。")
            self._load_saved_settings_list()
            return

        settings = all_saved[name]

        for k, (cb, widget) in self.controls.items():
            if k in settings:
                checked, val = settings[k]
                cb.setChecked(bool(checked))
                if isinstance(widget, QtWidgets.QSpinBox):
                    try:
                        widget.setValue(int(val))
                    except Exception:
                        pass
                    widget.setEnabled(bool(checked))
                else:
                    widget.setText(str(val))
                    widget.setEnabled(bool(checked))

        QtWidgets.QMessageBox.information(self, "加载成功", f"已加载设置: {name}")

    def _on_delete_clicked(self):
        name = self.load_combo.currentText().strip()
        if not name:
            QtWidgets.QMessageBox.warning(self, "删除失败", "请先选择一个已保存的设置名称。")
            return

        all_saved = self._read_saved_settings()
        if name not in all_saved:
            QtWidgets.QMessageBox.warning(self, "删除失败", "所选设置不存在。")
            self._load_saved_settings_list()
            return

        reply = QtWidgets.QMessageBox.question(
            self, "确认删除",
            f"确定要删除已保存设置: {name} ?",
            QtWidgets.QMessageBox.Yes | QtWidgets.QMessageBox.No
        )

        if reply != QtWidgets.QMessageBox.Yes:
            return

        del all_saved[name]
        ok = self._write_saved_settings(all_saved)
        if ok:
            QtWidgets.QMessageBox.information(self, "删除成功", f"已删除: {name}")
            self._load_saved_settings_list()
        else:
            QtWidgets.QMessageBox.warning(self, "删除失败", "删除时写入文件失败。")

    def _find_file_case_insensitive(self, target_name):
        target_lower = target_name.lower()
        for entry in os.listdir("."):
            if entry.lower() == target_lower:
                return entry
        return None

    def _build_cmd_list(self, exe_name):
        cmd_list = [exe_name]

        for k, (cb, widget) in self.controls.items():
            if not cb.isChecked():
                continue

            if k == "-n":
                cmd_list.append(k)
                cmd_list.append(str(widget.value()))
                continue

            if k in ("-httping", "-dd", "-allip"):
                cmd_list.append(k)
                continue

            val = widget.text().strip()
            if val == "":
                continue

            cmd_list.append(k)
            cmd_list.append(val)

        return cmd_list

    def _on_run_clicked(self):
        if self.is_running:
            return

        cfst_actual = self._find_file_case_insensitive(CFST_EXE)
        ip_actual = self._find_file_case_insensitive(IP_FILE_NAME)

        missing = []
        if not cfst_actual:
            missing.append(CFST_EXE)
        if not ip_actual:
            missing.append(IP_FILE_NAME)

        if missing:
            missing_str = "，".join(missing)
            QtWidgets.QMessageBox.warning(
                self, "文件缺失",
                f"未找到必要文件: {missing_str}\n请将缺失文件放在程序同目录后重试。"
            )
            return

        cmd_list = self._build_cmd_list(cfst_actual)

        # 切换到输出标签页
        self.tab_widget.setCurrentIndex(1)
        
        # 清空输出
        self.output_text.clear()
        self.progress_bar.setValue(0)

        # 使用 QProcess 运行
        self.process = QProcess(self)
        self.process.setProcessChannelMode(QProcess.MergedChannels)
        self.process.readyReadStandardOutput.connect(self._read_output)
        self.process.finished.connect(self._process_finished)

        self.output_text.append(f"[命令] {' '.join(cmd_list)}\n")
        self.output_text.append("=" * 50 + "\n")

        self.process.start(cmd_list[0], cmd_list[1:])
        
        self.is_running = True
        self.run_btn.setEnabled(False)
        self.stop_btn.setEnabled(True)

    def _read_output(self):
        """读取进程输出"""
        if self.process:
            data = self.process.readAllStandardOutput()
            text = bytes(data).decode('utf-8', errors='ignore')
            self.output_text.append(text)
            
            # 解析进度
            self._parse_progress(text)
            
            # 自动滚动到底部
            scrollbar = self.output_text.verticalScrollBar()
            scrollbar.setValue(scrollbar.maximum())

    def _parse_progress(self, text):
        """解析进度信息"""
        # 尝试从输出中解析进度
        import re
        
        # 匹配类似 "100/200" 或 "50%" 的进度
        match = re.search(r'(\d+)/(\d+)', text)
        if match:
            current = int(match.group(1))
            total = int(match.group(2))
            if total > 0:
                progress = int((current / total) * 100)
                self.progress_bar.setValue(min(progress, 100))
        
        # 匹配百分比
        match = re.search(r'(\d+)%', text)
        if match:
            progress = int(match.group(1))
            self.progress_bar.setValue(min(progress, 100))

    def _process_finished(self, exit_code, exit_status):
        """进程结束"""
        self.is_running = False
        self.run_btn.setEnabled(True)
        self.stop_btn.setEnabled(False)
        self.progress_bar.setValue(100)

        self.output_text.append("\n" + "=" * 50)
        self.output_text.append(f"\n[完成] 测速结束，退出码: {exit_code}")

        # 保存历史记录
        self._save_history()

        # 自动加载结果
        self._load_results()
        
        # 显示通知
        if self.tray_icon.isVisible():
            self.tray_icon.showMessage(
                "测速完成",
                "CloudflareSpeedTest 测速已完成，请查看结果",
                QtWidgets.QSystemTrayIcon.Information,
                3000
            )

    def _stop_test(self):
        """停止测速"""
        if self.process and self.is_running:
            self.process.kill()
            self.output_text.append("\n[中止] 用户手动停止测速")
            self.is_running = False
            self.run_btn.setEnabled(True)
            self.stop_btn.setEnabled(False)

    def _clear_output(self):
        """清空输出"""
        self.output_text.clear()
        self.progress_bar.setValue(0)

    def _load_results(self):
        """加载测速结果"""
        result_file = "result.csv"
        if not os.path.exists(result_file):
            self.result_info.setText("未找到 result.csv 文件")
            return

        try:
            with open(result_file, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                rows = list(reader)

            if len(rows) < 2:
                self.result_info.setText("result.csv 文件为空")
                return

            # 清空表格
            self.result_table.setRowCount(0)
            
            # 填充数据
            headers = rows[0]
            data_rows = rows[1:]

            self.result_table.setRowCount(len(data_rows))
            
            for row_idx, row in enumerate(data_rows):
                for col_idx, value in enumerate(row[:6]):
                    item = QtWidgets.QTableWidgetItem(value)
                    item.setFlags(item.flags() ^ Qt.ItemIsEditable)
                    self.result_table.setItem(row_idx, col_idx, item)

            self.result_info.setText(f"已加载 {len(data_rows)} 条结果")
            
            # 切换到结果标签页
            self.tab_widget.setCurrentIndex(2)

        except Exception as e:
            self.result_info.setText(f"加载失败: {str(e)}")

    def _filter_results(self, text):
        """过滤结果"""
        for row in range(self.result_table.rowCount()):
            match = False
            for col in range(self.result_table.columnCount()):
                item = self.result_table.item(row, col)
                if item and text.lower() in item.text().lower():
                    match = True
                    break
            self.result_table.setRowHidden(row, not match)

    def _copy_best_ip(self):
        """复制最优 IP"""
        if self.result_table.rowCount() == 0:
            QtWidgets.QMessageBox.warning(self, "复制失败", "没有可用的测速结果")
            return

        # 获取第一行的 IP
        ip_item = self.result_table.item(0, 0)
        if ip_item:
            ip = ip_item.text()
            clipboard = QApplication.clipboard()
            clipboard.setText(ip)
            
            QtWidgets.QMessageBox.information(self, "复制成功", f"最优 IP 已复制: {ip}")

    def _show_table_menu(self, pos):
        """显示表格右键菜单"""
        menu = QtWidgets.QMenu()
        
        copy_ip_action = menu.addAction("复制 IP")
        copy_row_action = menu.addAction("复制整行")
        
        action = menu.exec_(self.result_table.mapToGlobal(pos))
        
        if action == copy_ip_action:
            row = self.result_table.currentRow()
            if row >= 0:
                ip_item = self.result_table.item(row, 0)
                if ip_item:
                    QApplication.clipboard().setText(ip_item.text())
        elif action == copy_row_action:
            row = self.result_table.currentRow()
            if row >= 0:
                row_data = []
                for col in range(self.result_table.columnCount()):
                    item = self.result_table.item(row, col)
                    if item:
                        row_data.append(item.text())
                QApplication.clipboard().setText('\t'.join(row_data))

    def _update_ip_library(self):
        """更新 IP 库"""
        reply = QtWidgets.QMessageBox.question(
            self, "确认更新",
            "是否从网络更新 Cloudflare IP 库?\n\n将依次尝试以下源:\n" + "\n".join([f"• {url[:50]}..." for url in IP_UPDATE_URLS[:3]]),
            QtWidgets.QMessageBox.Yes | QtWidgets.QMessageBox.No
        )

        if reply != QtWidgets.QMessageBox.Yes:
            return

        self.update_ip_btn.setEnabled(False)
        self.update_ip_btn.setText("更新中...")

        # 使用线程更新
        from PyQt5.QtCore import QThread, pyqtSignal

        class UpdateThread(QThread):
            finished = pyqtSignal(bool, str)

            def run(self):
                for url in IP_UPDATE_URLS:
                    try:
                        response = requests.get(url, timeout=15)
                        if response.status_code == 200:
                            with open(IP_FILE_NAME, 'w', encoding='utf-8') as f:
                                f.write(response.text)
                            self.finished.emit(True, f"IP 库已更新\n来源: {url[:50]}...\n共 {len(response.text.splitlines())} 行")
                            return
                    except Exception as e:
                        continue
                self.finished.emit(False, "所有更新源均失败，请检查网络连接")

        def on_update_finished(success, message):
            self.update_ip_btn.setEnabled(True)
            self.update_ip_btn.setText("🔄 更新IP库")
            if success:
                QtWidgets.QMessageBox.information(self, "更新成功", message)
            else:
                QtWidgets.QMessageBox.warning(self, "更新失败", message)

        self.update_thread = UpdateThread()
        self.update_thread.finished.connect(on_update_finished)
        self.update_thread.start()

    def _save_history(self):
        """保存历史记录"""
        result_file = "result.csv"
        if not os.path.exists(result_file):
            return

        try:
            with open(result_file, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                rows = list(reader)

            if len(rows) < 2:
                return

            # 读取现有历史
            history = []
            if os.path.exists(HISTORY_FILE):
                try:
                    with open(HISTORY_FILE, 'r', encoding='utf-8') as f:
                        history = json.load(f)
                except:
                    history = []

            # 添加新记录
            record = {
                "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "best_ip": rows[1][0] if len(rows[1]) > 0 else "",
                "best_latency": rows[1][2] if len(rows[1]) > 2 else "",
                "best_speed": rows[1][4] if len(rows[1]) > 4 else "",
                "total_results": len(rows) - 1
            }
            history.insert(0, record)

            # 只保留最近50条
            history = history[:50]

            with open(HISTORY_FILE, 'w', encoding='utf-8') as f:
                json.dump(history, f, ensure_ascii=False, indent=2)

        except Exception as e:
            print(f"保存历史失败: {e}")

    def _show_history(self):
        """显示历史记录"""
        if not os.path.exists(HISTORY_FILE):
            QtWidgets.QMessageBox.information(self, "历史记录", "暂无历史记录")
            return

        try:
            with open(HISTORY_FILE, 'r', encoding='utf-8') as f:
                history = json.load(f)
        except:
            QtWidgets.QMessageBox.warning(self, "错误", "读取历史记录失败")
            return

        if not history:
            QtWidgets.QMessageBox.information(self, "历史记录", "暂无历史记录")
            return

        # 创建历史记录对话框
        dialog = QtWidgets.QDialog(self)
        dialog.setWindowTitle("测速历史记录")
        dialog.resize(600, 400)

        layout = QtWidgets.QVBoxLayout(dialog)

        table = QtWidgets.QTableWidget()
        table.setColumnCount(5)
        table.setHorizontalHeaderLabels(["时间", "最优IP", "延迟(ms)", "速度(MB/s)", "结果数"])
        table.horizontalHeader().setStretchLastSection(True)
        table.setRowCount(len(history))

        for row_idx, record in enumerate(history):
            table.setItem(row_idx, 0, QtWidgets.QTableWidgetItem(record.get("time", "")))
            table.setItem(row_idx, 1, QtWidgets.QTableWidgetItem(record.get("best_ip", "")))
            table.setItem(row_idx, 2, QtWidgets.QTableWidgetItem(record.get("best_latency", "")))
            table.setItem(row_idx, 3, QtWidgets.QTableWidgetItem(record.get("best_speed", "")))
            table.setItem(row_idx, 4, QtWidgets.QTableWidgetItem(str(record.get("total_results", ""))))

        layout.addWidget(table)

        # 按钮
        btn_layout = QtWidgets.QHBoxLayout()
        
        clear_btn = QtWidgets.QPushButton("清空历史")
        def clear_history():
            reply = QtWidgets.QMessageBox.question(
                dialog, "确认清空", "确定要清空所有历史记录?",
                QtWidgets.QMessageBox.Yes | QtWidgets.QMessageBox.No
            )
            if reply == QtWidgets.QMessageBox.Yes:
                try:
                    os.remove(HISTORY_FILE)
                    QtWidgets.QMessageBox.information(dialog, "成功", "历史记录已清空")
                    dialog.close()
                except:
                    pass
        clear_btn.clicked.connect(clear_history)
        
        close_btn = QtWidgets.QPushButton("关闭")
        close_btn.clicked.connect(dialog.close)
        
        btn_layout.addWidget(clear_btn)
        btn_layout.addStretch()
        btn_layout.addWidget(close_btn)
        
        layout.addLayout(btn_layout)

        dialog.exec_()


if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)

    # 全局图标
    if os.path.exists(APP_ICON):
        app.setWindowIcon(QtGui.QIcon(APP_ICON))

    w = MainWin()
    w.show()
    sys.exit(app.exec_())
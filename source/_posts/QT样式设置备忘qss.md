---
title: QT样式qss设置
categories: 
- QT编程
tags: 
- qss
- QT
---

# QT样式qss设置

## QLineEdit

```css
QLineEdit {
	border: 1px solid #A0A0A0; /* 边框宽度为1px，颜色为#A0A0A0 */
	border-radius: 3px; /* 边框圆角 */
	padding-left: 5px; /* 文本距离左边界有5px */
	background-color: #F2F2F2; /* 背景颜色 */
	color: #A0A0A0; /* 文本颜色 */
	selection-background-color: #A0A0A0; /* 选中文本的背景颜色 */
	selection-color: #F2F2F2; /* 选中文本的颜色 */
	font-family: "Microsoft YaHei"; /* 文本字体族 */
	font-size: 20pt; /* 文本字体大小 */
}

QLineEdit:hover { /* 鼠标悬浮在QLineEdit时的状态 */
	border: 1px solid #298DFF;
	border-radius: 3px;
	background-color: #F2F2F2;
        color: #298DFF;
        selection-background-color: #298DFF;
	selection-color: #F2F2F2;
}

QLineEdit[echoMode="2"] { /* QLineEdit有输入掩码时的状态 */
	lineedit-password-character: 9679;
	lineedit-password-mask-delay: 2000;
}

QLineEdit:disabled { /* QLineEdit在禁用时的状态 */
	border: 1px solid #CDCDCD;
	background-color: #CDCDCD;
	color: #B4B4B4;
}

QLineEdit:read-only { /* QLineEdit在只读时的状态 */
	background-color: #CDCDCD;
	color: #F2F2F2;
}

```

## QSpinbox

```css
SpinBox {
        border-radius: 4px;
        height: 24px;
        min-width: 40px;
        border: 1px solid rgb(100, 100, 100);
        font-size: 15px; 
        background:transparent; 
        border-width:0; 
        border-style:outset;
        /*background: rgb(255, 110, 29);*/
}
QSpinBox {
        border-radius: 4px;
        height: 24px;
        min-width: 40px;
        border: 1px solid rgb(100, 100, 100);
        /*background: rgb(255, 110, 29);*/
}
QSpinBox:enabled {
        color: rgb(220, 220, 220);
}
QSpinBox:enabled:hover, QLineEdit:enabled:focus {
        color: rgb(230, 230, 230);
}
QSpinBox:!enabled {
        color: rgb(65, 65, 65);
        background: transparent;
}
QSpinBox::up-button {
        width: 18px;
        height: 12px;
        border-top-right-radius: 4px;
        border-left: 1px solid rgb(100, 100, 100);
        image: url(:/Black/upButton);
        background: rgb(50, 50, 50);
}
QSpinBox::up-button:!enabled {
        border-left: 1px solid gray;
        background: transparent;
}
QSpinBox::up-button:enabled:hover {
        background: rgb(255, 255, 255, 30);
}
QSpinBox::down-button {
        width: 18px;
        height: 12px;
        border-bottom-right-radius: 4px;
        border-left: 1px solid rgb(100, 100, 100);
        image: url(:/Black/downButton);
        background: rgb(50, 50, 50);
}
QSpinBox::down-button:!enabled {
        border-left: 1px solid gray;
        background: transparent;
}
QSpinBox::down-button:enabled:hover {
        background: rgb(255, 255, 255, 30);
}
```


# 相机标定大全——平面、单目、双目、眼手

看完这标定总结你还不懂标定就来打我吧！

<!-- TOC -->

- [一、机器视觉几何坐标概论](#一机器视觉几何坐标概论)
    - [1、世界坐标系](#1世界坐标系)
    - [2、摄像机坐标系](#2摄像机坐标系)
    - [3、图像（像素）坐标系](#3图像像素坐标系)
        - [3.1、图像坐标系](#31图像坐标系)
        - [3.2、像素坐标系](#32像素坐标系)
    - [4、坐标系之间的**关系**](#4坐标系之间的关系)
        - [4.1、图像坐标系与像素坐标系](#41图像坐标系与像素坐标系)
        - [4.2、相机坐标系与图像坐标系](#42相机坐标系与图像坐标系)
        - [4.3、世界坐标系与相机坐标系](#43世界坐标系与相机坐标系)
        - [4.4、从世界坐标到像素坐标](#44从世界坐标到像素坐标)
- [二、平面标定（Homography变换）](#二平面标定homography变换)
    - [1、定义](#1定义)
    - [2、计算推导](#2计算推导)
    - [3、应用](#3应用)
        - [1、简单平面的转换](#1简单平面的转换)
        - [2、在四轴中求取2D点到3D点的转换关系](#2在四轴中求取2d点到3d点的转换关系)
            - [2.1 相机在手上](#21-相机在手上)
                - [2.1.1 转换方程](#211-转换方程)
                - [2.1.2 直接法](#212-直接法)
                - [2.1.3 旋转法](#213-旋转法)
            - [2.2 相机不在手上](#22-相机不在手上)
                - [2.2.1 转换方程](#221-转换方程)
                - [2.2.2 直接法](#222-直接法)
                - [2.2.3 圆弧法](#223-圆弧法)
            - [2.3 直接利用AXXB解决](#23-直接利用axxb解决)
            - [总结梳理](#总结梳理)
- [三、单目标定](#三单目标定)
    - [1、如何进行标定？（理想情况下无畸变）](#1如何进行标定理想情况下无畸变)
    - [2、实际情况下（有畸变）](#2实际情况下有畸变)
        - [2.1、径向畸变](#21径向畸变)
        - [2.2、切向畸变](#22切向畸变)
        - [2.3、总结](#23总结)
    - [3、疑问](#3疑问)
        - [3.1、标定的世界坐标从何而来](#31标定的世界坐标从何而来)
        - [3.2、一张图像也能得到标定结果](#32一张图像也能得到标定结果)
    - [4、自动标定](#4自动标定)
        - [eye in hand](#eye-in-hand)
        - [eye to hand](#eye-to-hand)
- [四、双目标定](#四双目标定)
    - [1、基本概念](#1基本概念)
        - [1.0、对极几何](#10对极几何)
        - [1.1、本征矩阵(Essential matrix)](#11本征矩阵essential-matrix)
        - [1.2、基础矩阵(Fundamental matrix)](#12基础矩阵fundamental-matrix)
        - [1.3、矩阵Q](#13矩阵q)
        - [1.4、bouguet极线矫正](#14bouguet极线矫正)
    - [2、计算](#2计算)
- [五、眼手标定](#五眼手标定)
    - [1、相机安装在机械手上](#1相机安装在机械手上)
    - [2、相机不安装在机械手上](#2相机不安装在机械手上)
    - [3、四轴tz的计算](#3四轴tz的计算)
    - [4、AXXB](#4axxb)

<!-- /TOC -->

## 一、机器视觉几何坐标概论

机器视觉系统有三大坐标系，分别是：1、世界坐标系，2、摄像机坐标系，3、图像（像素）坐标系；

### 1、世界坐标系

世界坐标系（Xw，Yw，Zw）是目标物体位置的参考系，根据运算方便自由设置圆点位置，可以位于机器手底座或者机器手前端执行器上。

其主要作用有

(1)盛放物体的三维坐标；

(2)标定的时候根据原点确定标定物的位置；

(3)给定出两个摄像机相对于世界坐标系的位置，从而求出两个或多个相机之间的坐标关系；

### 2、摄像机坐标系

摄像机坐标系（Xc，Yc，Zc）是摄像机在自己角度上的坐标系，原点在摄像机的光心上，Z轴与摄像机光轴平行，即摄像机的镜头拍摄方向。

### 3、图像（像素）坐标系

#### 3.1、图像坐标系

图像坐标系（x，y）单位米或毫米，是连续图像坐标或者空间坐标，以图片对角线交点作为基准原点建立的坐标系。

#### 3.2、像素坐标系

像素坐标系（u，v）单位尺度为一个pixel，是离散图像坐标或像素坐标，原点在图片的左上角。

### 4、坐标系之间的**关系**

当我们在图片中确定了某个物体的位置，如何让机器手去到空间中的实际位置进行抓取呢？这就需要对坐标进行转换。而从像素点到空间点的转换与空间点到像素点的转换是相反的，我们先将后者的推导过程。

#### 4.1、图像坐标系与像素坐标系

图像坐标系与像素坐标系的关系为：

$$
f(x)=
\begin{cases}
u = \frac{x}{dx} + u0 \\
v = \frac{y}{dy} + v0
\end{cases}
$$

dx代表一个像素的宽度（x方向），与x同单位，x/dx表示x轴上有多少个像素，同理y/dy表示y轴上的像素个数，(u0，v0)是图像平面中心。

<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/fixture.png" width="300" align=center />

将上述关系转换为矩阵形式：

$$
\left[
 \begin{matrix}
   u\\
   v\\
   1
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   \frac{1}{dx} & 0 & u0\\
   0 & \frac{1}{dy} & v0\\
   0 & 0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   x\\
   y\\
   1
  \end{matrix}
\right]
$$

#### 4.2、相机坐标系与图像坐标系

从相机坐标系到图像坐标系是一个三维坐标到二维坐标（3D->2D）的过程，称之为透视投影变换。为了求解它们之间的关系，将普通图像坐标（x，y）拓展为齐次坐标（x，y，1）。空间中的某点，投影到图像平面上的点与相机的光心在一条直线上。以光心为原点建立相机坐标系：

<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/fctofi.png" width="300" align=center />

根据相似三角形关系可以得到以下：

△ABO_c ~ △oCO_c

△PBO_c ~ △pCO_c

$$
\frac{AB}{oC} = \frac{AO_c}{oO_c} = \frac{PB}{pC} = \frac{X_c}{x} = \frac{Z_c}{f} =\frac{Y_c}{y}
$$

$$
x = f \cdot \frac{X_c}{Z_c},
y = f \cdot \frac{Y_c}{Z_c}
$$

f为相机焦距（相机光心到成像平面的距离）

用矩阵形式表示为：

$$
Zc
\left[
 \begin{matrix}
   x\\
   y \\
   1
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   f & 0 & 0 & 0\\
   0 & f & 0 & 0\\
   0 & 0 & 1 & 0
  \end{matrix}
\right]
\left[
 \begin{matrix}
   Xc\\
   Yc\\
   Zc\\
   1
  \end{matrix}
\right]
$$

统一将成像平面上的点用(u,v)表示：

$$
Z
\left[
 \begin{matrix}
   u \\
   v \\
   1
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   f & 0 & 0 & 0\\
   0 & f & 0 & 0\\
   0 & 0 & 1 & 0
  \end{matrix}
\right]
\left[
 \begin{matrix}
   Xc\\
   Yc\\
   Z\\
   1
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   f \cdot Xc\\
   f \cdot Yc\\
   1
  \end{matrix}
\right]
$$

得图像点与空间点的关系为：

$$
u =\frac {f \cdot X_c}{Z},
v =\frac {f \cdot Y_c}{Z}
$$

#### 4.3、世界坐标系与相机坐标系

世界坐标（Xw，Yw，Zw）与相机坐标（Xc，Yc，Zc）同为三维坐标（右手系，三轴互相垂直），两个坐标系的关系为刚体变换（刚体变换：当物体不发生形变时，对一个几何物体作旋转，平移的运动）。可以先凭空想象下，有两个坐标系A与B，如何将A坐标系下的坐标转换到B坐标系表示，首先将A坐标系以原点为基准任意旋转，使其x轴，y轴，z轴与B坐标轴平行且同方向，接着平移AB坐标系原点的直线距离，就可以将A坐标系下的坐标转换到B坐标系，这个旋转Rotation与平移Transport就是需要求得的两个三维坐标之间的关系。

用以下等式表示两个坐标系之间的关系：

$$
\left[
 \begin{matrix}
   Xc\\
   Yc \\
   Zc
  \end{matrix}
\right]=
R
\left[
 \begin{matrix}
   Xw\\
   Yw\\
   Zw
  \end{matrix}
\right]
+T
$$

其中旋转矩阵R可以看成空间坐标分别沿着X，Y，Z轴的三个旋转矩阵点乘得到的结果。

当绕Z轴旋转$\theta$角度，新旧坐标的关系为：

$$
\begin{cases}
x = x'cos\theta - y'sin\theta \\
y = x'sin\theta + y'cos\theta \\
z = z'
\end{cases}
$$

用矩阵表示为：

$$
\left[
 \begin{matrix}
   x\\
   y \\
   z
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   cos\theta & -sin\theta & 0\\
   sin\theta & cos\theta & 0\\
   0 & 0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   x'\\
   y'\\
   z'
  \end{matrix}
\right]=
R1
\left[
 \begin{matrix}
   x'\\
   y' \\
   z'
  \end{matrix}
\right]
$$

同理，绕X轴，Y轴旋转$\delta$和$\omega$角度，可以得到：

$$
\left[
 \begin{matrix}
   x\\
   y \\
   z
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   1 & 0 & 0\\
   0 & cos\delta & sin\delta
\\
   0 & -sin\delta
 & cos\delta
\\
  \end{matrix}
\right]
\left[
 \begin{matrix}
   x'\\
   y'\\
   z'
  \end{matrix}
\right]=
R2
\left[
 \begin{matrix}
   x'\\
   y' \\
   z'
  \end{matrix}
\right]
$$

$$
\left[
 \begin{matrix}
   x\\
   y\\
   z
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   cos\omega & 0 & -sin\omega\\
   0 & 1 & 0\\
   sin\omega & 0 & cos\omega
  \end{matrix}
\right]
\left[
 \begin{matrix}
   x'\\
   y'\\
   z'
  \end{matrix}
\right]=
R3
\left[
 \begin{matrix}
   x'\\
   y' \\
   z'
  \end{matrix}
\right]
$$

于是，得到旋转矩阵R = R1\*R2\*R3，维度为3X3，T为平移矩阵，维度为3X1。

拓展为其次坐标：

$$
\left[
 \begin{matrix}
   Xc\\
   Yc \\
   Zc \\
   1
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   R & T\\
   0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   Xw\\
   Yw\\
   Zw\\
   1
  \end{matrix}
\right]
$$

#### 4.4、从世界坐标到像素坐标

综合上面推导的过程，

```mermaid
graph LR
A[世界坐标] --> B[相机坐标]
B --> C[理想图像坐标]
C -- 不考虑畸变--> D[像素坐标]
```

以上顺序用矩阵表示为不断左乘下一步，即：

$$
Zc
\left[
 \begin{matrix}
   u\\
   v \\
   1
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   \frac{1}{dx} & 0 & u0\\
   0 & \frac{1}{dy} & v0\\
   0 & 0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   f & 0 & 0 & 0\\
   0 & f & 0 & 0\\
   0 & 0 & 1 & 0
  \end{matrix}
\right]
\left[
 \begin{matrix}
   R & T\\
   0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   Xw\\
   Yw\\
   Zw\\
   1
  \end{matrix}
\right]
$$

等式右边的前两个矩阵称的乘积为相机内参，第三个矩阵称为相机外参(Toc)，后面的单目相机标定，就是为了求解相机的内外参数。

至此，机器视觉几何坐标概论记录完了，接下来会陆续记录我所参与的项目中包含标定的内容。

## 二、平面标定（Homography变换）

### 1、定义

单应性(homography)变换用来描述物体在两个平面之间的转换关系，是对应齐次坐标下的线性变换，可以通过矩阵表示：

$$
X' = H·X
$$

### 2、计算推导

带入数据（x,y）为图片上的点位置：

$$
\left[
 \begin{matrix}
   x'\\
   y'\\
   w
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   h1 & h2 & h3\\
   h4 & h5 & h6\\
   h7 & h8 & h9
  \end{matrix}
\right]
\left[
 \begin{matrix}
   x\\
   y\\
   1
  \end{matrix}
\right]
$$

因为是齐次坐标系，方程左右同时除h9

$$
\left[
 \begin{matrix}
   x1'\\
   y1'\\
   w'
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   \frac{x'}{h9}\\
   \frac{y'}{h9}\\
   \frac{z'}{h9}
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   h1' & h2' & h3'\\
   h4' & h5' & h6'\\
   h7' & h8' & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   x\\
   y\\
   1
  \end{matrix}
\right]
$$

将矩阵展开得到：

公式①：
$$
\begin{cases}
x1' = h1'x+h2'y+h3' \\
y1' = h4'x+h5'y+h6' \\
w' = h7'x+h8'y+h9'
\end{cases}
$$
将下面的矩阵用已知的观测值代替：

$$
\left[
 \begin{matrix}
   x1'\\
   y1'\\
   w'
  \end{matrix}
\right]
==>(x^R, y^R)
$$

根据齐次坐标的齐次性质：

公式②：
$$
\frac{x1'}{w'}=x^R,\frac{y1'}{w'}=y^R
$$

结合公式①②：

公式③：
$$
\begin{cases}
x^R =  \frac{h1'x+h2'y+h3'}{h7'+h8'+1}\\
y^R =  \frac{h4'x+h5'y+h6'}{h7'+h8'+1}
\end{cases}
$$
在公式③中

$$
(x, y)，(x^R, y^R)
$$
为观测到的已知参数，未知参数有h1'~h8'共8个，一对点能够产生两个方程，则求解公式③至少需要四组点对，才能求出h1'~h8'。一般的数据会多于4组点对，用最小二乘法或ransac来获取最优参数。

求解过后，h1'~h8'为已知，

$$
H'=
\left[
 \begin{matrix}
   h1' & h2' & h3'\\
   h4' & h5' & h6'\\
   h7' & h8' & 1
  \end{matrix}
\right]
$$
可用于单应性变换的计算。

### 3、应用

#### 1、简单平面的转换

图片A中的点P为(x,y)，求对应在另外一个视角的图片B点P’(x',y')？

$$
\left[
 \begin{matrix}
   x2\\
   y2\\
   z2
  \end{matrix}
\right]=
H'
\left[
 \begin{matrix}
   x\\
   y\\
   1
  \end{matrix}
\right]
$$

$$
P'(x',y') = (\frac{x2}{z2},\frac{y2}{z2})
$$

--------------------------------------------------------2020更新 华丽的分割线--------------------------------------------------------

#### 2、在四轴中求取2D点到3D点的转换关系

##### 2.1 相机在手上

求取

$$
{^r}H{_c}
$$

###### 2.1.1 转换方程

$$
{^rP_o =  ^rT_t \cdot ^tH_C \cdot ^CP_o}
$$

参数解释：

$^rP_o$(4×1)：object在Robot坐标系下的表示

$^rT_t$(4×4)：Tool到Robot的转换矩阵，即机械手示教器上读回的数值

$^tH_C$(3×3)：图像平面h1到Tool平面转换矩阵

$^CP_o$(2×1==齐次变化==>3×1)：图像中的点

###### 2.1.2 直接法

计算：delta pos 与图像点平面的关系

$$
^tT_r \cdot ^{ri}P_o =  ^tH_C \cdot ^{Ci}P_o
$$

参数解释：$^tT_r$保持不变，$^tH_C$为所求的参数，$^{Ci}P_o$与$^{ri}P_o$一一对应。

适用条件：u轴不变的情况，末端执行器与机械手只存在x、y的偏移量。

(提示：机械手位姿数目==图像数目+1)

该方法得到的H矩阵是图像点与△Pos (△Pos = $P_i - P_{origin}$) 之间的关系，所以在后期的使用中，需要先确定一个$P_{origin}$，再利用图像与Homo关系得到△Pos，再叠加上$P_{origin}$，得到新的一个$^rP_i$。

操作过程：

<div align="center"><img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/plane_calibration_4axis_dir_flow.png" /></div>

为什么直接法所需要的数据，机械手poses会比图像坐标多一个呢？
解答：根据操作流程，先选择一个能够看到标定板的位置，作为基准点。
采集数据过程：手动更换标定板位置依旧在视野中$img_i$，控制机械手末端到标定板上点$pose_i$，循环往复多次采集。

###### 2.1.3 旋转法

计算:Pot 与 图像点平面的关系

$$
^{ti}T_r \cdot ^rP_o =  ^tH_C \cdot ^{Ci}P_o
$$

参数解释：$^rP_o$为旋转法所求量，保持不变，$^tH_C$为所求的参数，$^{Ci}P_o$与$^{ti}T_r$一一对应。

操作过程(保持标定板不能动)：

<div align="center"><img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/plane_calibration_4axis_cam_in_hand_rot_flow.webp" /></div>
<div align="center"><img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/plane_calibration_4axis_cam_in_hand_rotation.png" /></div>

旋转前后分别记下tool的坐标为

$$
^rP_1\;
^rP_2
$$

则可以求得object在robot下的坐标：

$$
^rP_o = (^rP_1+^rP_2)/2
$$
<!-- $$
^rP{_o}=\frac{^rP_1+^rP_2}{2}
$$ -->

标定过程：在标定板与相机视野内的前提下移动机械手(xy平面，z,u,v,w保持不变)并拍摄图片，存储每个位置与每张图片，采集9组数据，将采集的数据连入PlaneCalibration工具，计算标定结果。

产生的数据为：旋转法对应的两张图片与两个机械手位姿，九点标定对应的九张图片与九个机械手位姿数据。将图像整合在一个文件夹里，机械手位姿整合在一份文件里，按顺序保存，注意数据的对应关系。

标定过程只用到了标定板上的某个点作为object，当选定了某个点A，你的旋转法就需要保持点A在图像中位置不变。用标定板的作用是为了在视野中更好地识别点A，当你的目标够明显，也可以不适用标定板(一般不采用)。

使用如上方法，根据图像中object的点，能得到它在Robot坐标系(xy平面，z,u,v,w保持不变)的位置，就可以将坐标发给机械手执行，该方法不用求取相机的内外参数，不考虑图像的畸变，可以用于对精度要求不高的项目。

##### 2.2 相机不在手上

求取相机坐标系与机械手的底座坐标系的变换关系

$$
{^r}H{_c}
$$

###### 2.2.1 转换方程

$$
^rT_t\cdot ^tP_o = ^rP_o = ^rH_c \cdot ^cP_o
$$

参数解释：

$^rT_t$(4×4)：Tool到Robot的转换矩阵，即机械手示教器上读回的数值

${^r}P{_o}$(3×1)：object在robot下的位置

${^r}H{_c}$(3×3)：图像平面h1到Tool平面转换矩阵

${^c}P{_t}$(2×1==齐次变化==>3×1)：tool在图像中的点

###### 2.2.2 直接法

$$
^rP_o = ^rH_c \cdot ^cP_o
$$

标定过程：

<div align="center"><img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/plane_calibration_4axis_dir_flow.png" /></div>

###### 2.2.3 圆弧法

$$
^rP_o = ^rH_c \cdot ^cP_o
$$

圆弧法需要将标定板绑在机械手上，该方法也是为了找到$^rP_o$与$^cP_o$两个数据集间的转换关系。每个Poc都需要由3张相同xy(robot base)坐标下相机拍得的图像，用拟合圆心的方法得到。**object定义为拟合得到的圆心**，即机械手最末端。

(3张图像拟合的圆心是在本软件中使用的默认图像张数，所以该方法所需要的机械手位姿点数与图像张数必须相等，且是3的倍数。)

因为只是标定两个平面之间的关系，$^rP_o$的xy与$^rT_t$的xy数据相同。

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/plane_calibration_4axis_cam_to_hand_circle.png" style="zoom:100%" />
</center>


用圆弧法需要将标定板绑在机械手上，该方法也是为了找到$^rP_o$与$^cP_o$两个数据集间的转换关系

操作步骤：

<div align="center"><img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/plane_calibration_4axis_cam_to_hand_circle_flow.png" /></div>

##### 2.3 直接利用AXXB解决

eye in hand：

$$
^rT_o=^rT_t \cdot ^tT_c \cdot ^cT_o
$$

列两个方程：
$$
^rT_o=^rT_t^{1} \cdot ^tT_c \cdot ^cT_o^{1}
$$
$$
^rT_o=^rT_t^{2} \cdot ^tT_c \cdot ^cT_o^{2}
$$

列出方程：
$$
^rT_t^{1} \cdot ^tT_c \cdot ^cT_o^{1}=^rT_t^{2} \cdot ^tT_c \cdot ^cT_o^{2}
$$

化简得:
$$
^tT_r^{1} \cdot ^rT_t^{2} \cdot ^tT_c=^tT_c \cdot ^cT_o^{1} \cdot ^oT_c^{2}
$$

$$
AX=XB
$$

eye to hand:

标定板绑在手末端

$$
^tT_o=^tT_r \cdot ^rT_c \cdot ^cT_o
$$

列两个方程：
$$
^tT_o=^tT_r^{1} \cdot ^rT_c \cdot ^cT_o^{1}
$$

$$
^tT_o=^tT_r^{2} \cdot ^rT_c \cdot ^cT_o^{2}
$$

$$
^tT_r^{1} \cdot ^rT_c \cdot ^cT_o^{1}=^tT_r^{2} \cdot ^rT_c \cdot ^cT_o^{2}
$$

化简得:
$$
^rT_t^{2} \cdot ^tT_r^{1} \cdot ^rT_c = ^rT_c \cdot ^cT_o^{2} \cdot ^oT_c^{1}
$$

$$
AX=XB
$$

##### 总结梳理

眼在手上，通过图像点Poc与Pot的关系，平面标定出Tct。

建模版子来,图像点Poc与标定量Tct,得到Pot, Pot与Ttr得到Por，就是现在图像点在Robot下的3d位置，多个图像点计算多个Por

实际板子来，同上一步骤，计算新的多个Por，与建模的Por计算homo关系，应用到示教点，得到新的电胶点，over～

## 三、单目标定

从之前的
[从世界坐标到像素坐标](#####4.4、从世界坐标到像素坐标)可以得到：

$$
Zc
\left[
 \begin{matrix}
   u\\
   v \\
   1
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   \frac{1}{dx} & 0 & u0\\
   0 & \frac{1}{dy} & v0\\
   0 & 0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   f & 0 & 0 & 0\\
   0 & f & 0 & 0\\
   0 & 0 & 1 & 0
  \end{matrix}
\right]
\left[
 \begin{matrix}
   R & T\\
   0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   Xw\\
   Yw\\
   Zw\\
   1
  \end{matrix}
\right]
$$

相机标定也是利用了上面这个公式，等式右边前两个矩阵乘积为相机内参，第三为相机外参(也成为Toc)。

各个参数的含义：dx代表一个像素的宽度（x方向），与x同单位，x/dx表示x轴上有多少个像素，同理y/dy表示y轴上的像素个数，(u0，v0)是图像平面中心。相机模型类似小孔成像模型，自行百度，也可参考前面的坐标转换关系[相机坐标系与图像坐标系](#####4.2、相机坐标系与图像坐标系)与[世界坐标系与相机坐标系](#####4.3、世界坐标系与相机坐标系)。

举个实际的例子,相机内参为：

$$
K =
\left[
 \begin{matrix}
   \frac{f}{dx} & 0 & u0\\
   0 & \frac{f}{dy} & v0\\
   0 & 0 & 1
  \end{matrix}
\right]
$$

### 1、如何进行标定？（理想情况下无畸变）

单目标定的目的就是为了得到**dx,dy,f,R,T**这几个参数（暂时不考虑畸变参数）。而最开始接触标定只是按照不同姿势地摆放标定板，前提当然要固定相机位置，为什么要这么做呢。

设有N个角点，K个棋盘，则可以列出2NK个方程，未知参数有4+6K个，所以从理论上来说，方程组数大于未知数个数就能解出未知数，即2NK>=6K+4，即(N-3)K>=2，但对于同一个平面来说，4个角点确定了一个与投影平面共面的四边形，在四个方向同时延伸就可以变成任意四边形，所以N的约束即为4，那么就只有K>=2这个条件，理论上至少需要两个视场列得到的2×4×2=16个方程才能求得4+6×2=16个参数。但是考虑噪声和数值稳定性，图片上的角点可以取多后采用最小二乘法、ransac或其他方法取最优参数。一般标定取10幅7×7或7×8角度不同的图片。到此为止，求出了**dx,dy,f,R,T**这几个参数。  

当然，标定还有另外一种方式，对于eye in hand 这种case，可以固定标定板，相机在机械手上，随着机械手变化位置，去不同的点位拍照，(当硬件结构确定情况下的大批量生产情况采用这种自动标定方式可以节约人力成本，)提前预设好几个位置，让机械手随机在附近进行拍照，完成内外参的标定。

### 2、实际情况下（有畸变）

理想的针孔模型透过小孔的光线少，导致了相机的曝光时间慢，实际中为了加快图像的生成使用透镜，但同时也引入了畸变。所以畸变发生在相机内部，所需要增加的相应计算多了几个畸变参数(会在下面定义),计算方法参照的方程式仍然是从世界坐标系到像素坐标的转换Tpw，常见的畸变有(1)径向畸变，(2)切向畸变。  

```mermaid
graph RL
A[世界坐标] --> B[相机坐标]
B --> C[理想图像坐标]
C -- 不考虑畸变--> D[像素坐标]
C -- 畸变 --> E[实际图像坐标]
E --> D
```

如果你用opencv的接口，会有最多(k1,k2,p1,p2[,k3[,k4,k5,k6[,s1,s2,s3,s4[,τx,τy]]]])这么多个畸变参数。

#### 2.1、径向畸变

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/radialdistortionmodel.jpeg"/>
</center>


径向畸变的现象有桶形失真与枕形失真。在成像仪光轴中心的畸变为0，沿着镜头半径方向向边缘移动，径向位移增大，畸变越来越严重。畸变的数学模型用参数**k1,k2,k3,k4,k5,k6**（或更多）描述，用主点的泰勒级数展开式前三项（或更多）表示：

$$
\begin{cases}
x_{correct} =  x(1+k_1r^2+k_2r^4+k_3r^6+...)\\
y_{correct} =  y(1+k_1r^2+k_2r^4+k_3r^6+...)
\end{cases}
$$

#### 2.2、切向畸变

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/tangentialdistortionmodel.jpeg"/>
</center>


切向畸变是由于透镜的安装偏差产生，导致透镜本身与相机成像平面不平行。切向畸变模型用参数**p1,p2**描述：

$$
\begin{cases}
x_{correct} =  x+[2p_1xy+p_2(r^2+2x^2)]\\
y_{correct} =  y+[2p_2xy+p_1(r^2+2y^2)]
\end{cases}
$$
(r为该点距离成像中心距离)

#### 2.3、总结

综合以上两种畸变，得到畸变矫正前后的坐标对应（理想图像坐标到实际图像坐标）关系：

$$
\left[
 \begin{matrix}
   x_c\\
   y_c
  \end{matrix}
\right]=
(1+k_1r^2+k_2r^4+k_3r^6)
\left[
 \begin{matrix}
   x_p\\
   y_p
  \end{matrix}
\right]
+
\left[
 \begin{matrix}
   2p_1xy+p_2(r^2+2x^2)\\
   2p_2xy+p_1(r^2+2y^2)
  \end{matrix}
\right]
$$

此时，世界坐标系到像素坐标系的关系就多了一个畸变转换：

$$
Zc
\left[
 \begin{matrix}
   u\\
   v \\
   1
  \end{matrix}
\right]=
\left[
 \begin{matrix}
   \frac{1}{dx} & 0 & u0\\
   0 & \frac{1}{dy} & v0\\
   0 & 0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   distor transform
  \end{matrix}
\right]
\left[
 \begin{matrix}
   f & 0 & 0 & 0\\
   0 & f & 0 & 0\\
   0 & 0 & 1 & 0
  \end{matrix}
\right]
\left[
 \begin{matrix}
   R & T\\
   0 & 1
  \end{matrix}
\right]
\left[
 \begin{matrix}
   Xw\\
   Yw\\
   Zw\\
   1
  \end{matrix}
\right]
$$

畸变转换至少包含五个参数**k1,k2,k3,p1,p2**,标定需要求得的未知数就有4+5+6K个，所以，为了标定结果的准确性，前面提到的标定取10幅7×7或7×8角度不同的图片是很有必要的。

### 3、疑问

#### 3.1、标定的世界坐标从何而来

给予标定板的建立世界坐标的xy轴，z轴垂直标定板射出，原点位置定义为标定板的圆孔的第一个点。

#### 3.2、一张图像也能得到标定结果

N的约束4还要保留吗？

一张图片确实可以得到标定结果，会有很多解。

### 4、自动标定

由于标定过程比较繁杂，无非就是尽可能多的在工作平面附近拍摄标定板的图片进行计算。使用机械手自动走点位进行拍照的方法较为节省人力成本。(球面)

本次分析参考：[自动标定分析](https://blog.csdn.net/qq_34193345/article/details/104631302)

#### eye in hand

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/eye_in_hand.png"/>
</center>


原始位置:
$$
^rT_o = ^rT_t \cdot ^tT_c \cdot ^cT_o
$$
新位置:
$$
^rT_o = ^rT_t^{'} \cdot ^tT_c \cdot ^cT_o^{'}
$$

$$
^cT_o^{'} = ^cT_o \cdot T
$$

结合以上两个公式，移项化简得：
$$
^rT_t^{'} = ^rT_o \cdot  T^{-1} \cdot ^oT_t
$$

#### eye to hand

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/eye_to_hand.png"/>
</center>


与eye in hand同理
原始位置:
$$
^rT_c = ^rT_t \cdot ^tT_o \cdot ^oT_c
$$
新位置:
$$
^rT_c = ^rT_t^{'} \cdot ^tT_o \cdot ^oT_c^{'}
$$

$$
^oT_c^{'} = T^{-1} \cdot ^oT_c
$$

结合以上两个公式，移项化简得：
$$
^rT_t^{'} = ^rT_o \cdot  T \cdot ^oT_t
$$

以上的T均假设移动的object的偏移量。

## 四、双目标定

为了得到图片中物体的深度信息，引入双目视觉。

双目标定在[单目标定](##三、单目标定)的基础上，标定出左右摄像机坐标系之间的相对关系。

### 1、基本概念

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/stereocam.png"/>
</center>


所涉及的专业名词有对极几何，本征矩阵，基础矩阵。

双目相机基于对极几何的理论，本征矩阵E(essential_matrix)包含在物理空间两个摄像机相关的旋转与平移信息，基础矩阵F(fundamental_matrix)除了包含E的信息还包括两个相机的内参数。E是几何意义上的，与成像仪无关，将左相机观测到的点P的坐标与右相机观测到的相同点的坐标关联起来(**相机坐标系下**)，F则是将左相机的像平面上的点与右相机观测到的像平面上相同点关联起来(**像素坐标系**)。

#### 1.0、对极几何

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/EpipolarGeometry.png"/>
</center>


立体成像系统的几何基础被称作“对极几何”

投影点：XL，XR

极点：相机光心投影到另一个相机的像平面上，eL，eR。

基线:两摄像机光心之间的距离

极线：直线Ol-XL因为与左相机的光学中心对其，所以在左相机被视为一个点（直线上的任意一点都投影到像平面上的XL点），但是，右侧相机会将此视为图像平面的一条线（图中红线），这条在右侧相机像平面上的直线eR-XR称为极线，同理，左相机像平面上的直线XL-eL也称为极线。

极线平面：XL-eL-eR-XR构成的平面

主点：主光线和相平面的相交位置OL，OR，两对极点与主点在同一3D直线上。

摄像机视图中的每一个三维点都被包含在与每个图像相交的极面中，二者相交产生的直线是极线。  
给定一幅图像的特征，在另一图像的匹配视图一定位于对应极线。这称为“极线约束” 。
极限约束意味着，一旦我们知道立体实验设备之间的对极几何，在两幅图像中匹配的二维搜索可以转变为沿着极线的一维搜索。

#### 1.1、本征矩阵(Essential matrix)

本征矩阵用字母E来表示，物理意义是左右相机坐标系相互转换的矩阵,表示几何意义，与单成像仪无关，用来描述左右相机图像平面上对应点**在各自相机坐标系**之间的关系。

特性：  
1）本质矩阵是由对极约束定义的。由于对极约束是等式为0的约束，所以对E乘以任何非零常数后，对极约束依然满足。这一点被称为E在不同尺度下是等价的。  
2）根据E=t∧R，可以证明，本质矩阵E的奇异值必定式[σ,σ,0]T。这称为本质矩阵的内在性质。可以理解为：一个3×3的矩阵是本征矩阵的充要条件是对它奇异值分解后，它有两个相等的奇异值，并且第三个奇异值为0。  
3）由于平移和旋转各有3个自由度，所以t∧R共有6个自由度。但由于尺度等价性，故E实际上只有5个自由度。

#### 1.2、基础矩阵(Fundamental matrix)

给本征矩阵E增加相机内参矩阵M的相关信息，就能得到描述同一个物理点在左右相机图像平面上对应点**在各自像素坐标系**下的关系。

参考: [opencv官方文档](https://docs.opencv.org/4.0.0/d9/d0c/group__calib3d.html#gae420abc34eaa03d0c6a67359609d8429)

极线模型(两像素点关系)：

$$
[P_2:1]^T \cdot F \cdot[P_1:1] = 0
$$

#### 1.3、矩阵Q

矩阵Q实现了视差图$disparity(x,y)$到3D世界坐标$(X,Y,Z,W)$

$$
\left[
 \begin{matrix}
   X & Y & Z &W
  \end{matrix}
\right]^T
=
Q*
\left[
 \begin{matrix}
   x & y & disparity(x,y) & 1
  \end{matrix}
\right]^T
$$

$$
\left[
 \begin{matrix}
   1 & 0 & 0 & -c_x\\
   0 & 1 & 0 & -c_y\\
   0 & 0 & 0 & f\\
   0 & 0 & -1/T_x & (c_x-c_x^{'})/T_x
  \end{matrix}
\right]
$$

$(c_x, c_y)$左相机主点坐标，$(c_x^{'}, c_y^{'})$右相机主点坐标，双目矫正后$c_y==c_y^{'}$成立，$f$焦距，$T_x$基线长，即两相机光心之间的距离。

#### 1.4、bouguet极线矫正

为了进行深度计算与三维重建，应该在双目标定之后先进行极线矫正。

校正前两个相机的光轴是一个倒V字形，如上对极几何图形所示，左右相机像平面不平行，极点在像平面上；

相比，校正后两相机光轴平行，像点在左右图像上的高度一致(极线矫正目的)，是为了做立体匹配时，只需要在同一行上搜索左右像平面的匹配点，提升效率。

矫正方法：将双目标定所求的基础矩阵(含RT)，分解成左右相机各旋转平移一半为Rl,Tl与Rr,Tr，分解原则为左右图像重投影畸变最小，左右的共同面积最大。

旋转后，左右相机的光轴平行，两成像面平行，没有行对准。

构造旋转矩阵使得基线与成像平面平行，构造方法通过右相机相对左相机的偏移矩阵T完成。

为了使得左相机的极点变换到无穷远（极线水平），左右相机投影中心之间的平移向量就是左极线方向。

### 2、计算

假设空间中一点P，其在世界坐标系下的坐标为Pw，左相机到右相机的关系为R,T，其在左右相机坐标系下的坐标可以表示为：

$$
\begin{cases}
P_{l} =  R_lP_w+T_l\\
P_{r} =  R_rP_w+T_r
\end{cases}
$$

其中

$$
P_r = RP_l+T
$$

结合以上两个公式，推得：

$$
\begin{cases}
R = R_rR_l^T\\
T = T_r-RT_l
\end{cases}
$$

奇异值分解？

## 五、眼手标定

眼手标定根据相机的安装方式不同，分别求解的是相机到机械手末端轴的坐标变换关系(相机在手上)

$$
{^T}T{_C}
$$
或相机到机械手底座的坐标变换关系(相机不在手上)

$$
{^R}T{_C}
$$

### 1、相机安装在机械手上

此种相机安装方式(Eye in hand)，**标定量为相机与机械手末端之间的关系**。

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/eye_in_hand.png"/>
</center>


标定方法: 固定标定板与机械手底座不变，移动机械手至两个位置1、2，分别记录两个位置下的相机图像，机械手位置。

假设空间中一物体(object)，机械手需要使用(眼在手上的相机)拍摄物体，得到物体在图片中的位置Pimg(x,y)，通过之前的单目相机标定，能够将此坐标转换到相机坐标系下的表示，即：
$$
P_{cam} = {^C}T{_O} * P_{img}
$$

然而，控制机械手抓取物体的动作，调整的是基于机械手底座(Robot)坐标系的xyzuvw变化，所以还需要求解相机坐标系到机械手底座坐标系的转换，即：

$$
{^R}T{_C} = {^R}T{_T} {^T}T{_C}
$$

${^R}T{_T}$：机械手末端到机械手底座
${^T}T{_C}$：相机到机械手末端

在已知机械手末端到机械手底座关系的条件下，未知量只有相机到机械手末端转换矩阵：

$$
{^T}T{_C}
$$
移动机械手分别到位置1与位置2，**以标定板到底座的固定关系(转换关系不变)，建立1、2两个位置下的恒等式。**

令：$X = {^T}T{_C}$
$$
{^R}T{_O} = {^R}T1{_T}\cdot X\cdot {^C}T1{_O} = {^R}T2{_T}\cdot X\cdot {^C}T2{_O}
$$

以上方程式的未知数只有X一个，可以将方程化成：

$$
{^R}T2{^{-1}_T}\cdot{  {^R}T1{_T}\cdot X \cdot {^C}T1{_O} } \cdot {^C}T1{^{-1}_O} ={^R}T2{^{-1}_T} \cdot{  {^R}T2{_T} \cdot X \cdot {^C}T2{_O} } \cdot {^C}T1{^{-1}_O}
$$

即：

<!-- $$
{
  {^R}T1{_T}\cdot X = X \cdot {^C}T2{_O}
}
$$ -->

$$
{^R}T2{^{-1}_T}\cdot{  {^R}T1{_T}\cdot X = X \cdot {^C}T2{_O} } \cdot {^C}T1{^{-1}_O}
$$

化简为：

$$
A \cdot X = X \cdot B
$$

### 2、相机不安装在机械手上

此种相机安装方式(Eye to hand)需要将标定板固定在机械手末端，保持机械手末端(Tool)与物体(Object)的位置关系不变，**标定量为相机到机械手底座之间的关系**。

<center>
<img src="https://raw.githubusercontent.com/JockerLin/NotesImageLib/master/eye_to_hand.png"/>
</center>


方法同 [相机安装在机械手上](###1相机安装在机械手上)，分别移动机械手到位置1与位置2，**以标定板到机械手末端的固定关系(转换关系不变)，建立1、2两个位置下的恒等式。**

令：$X = {^R}T{_C}$
$$
{^T}T{_O} = {^T}T1{_R}\cdot X\cdot {^C}T1{_O} = {^T}T2{_R}\cdot X\cdot {^C}T2{_O}
$$

以上方程式的未知数只有X一个，可以将方程化成：

$$
{^T}T2{^{-1}_R}\cdot {{^T}T1{_R}\cdot X \cdot {^C}T1{_O}
} \cdot {^C}T1{^{-1}_O} ={^T}T2{^{-1}_R} \cdot { {^T}T2{_R} \cdot X \cdot {^C}T2{_O}
} \cdot {^C}T1{^{-1}_O}
$$

化简为：

$$
A \cdot X = X \cdot B
$$

AX=XB的求解方法，暂时不列举，到这一步为止，就可以假设已经求出了X即眼手标定结果。

### 3、四轴tz的计算

Z_SCARA_Heigh 定义为四轴手的高度，在计算眼手关系时候粗略给定值。

拿所有位姿的第一个Toc来计算：

eye in hand： Tct * Toc = > Tot，提取Tot的Z分量z_calib=Tot[2,3]，需要修正的tz=Z_SCARA_Heigh-z_calib

eye to hand：Tcr * Toc = > Tor，提取Tor的Z分量z_calib=Tor[2,3]，需要修正的tz=Z_SCARA_Heigh-z_calib

Tcr * Toc = > Tor, Trt * Tor => Tot，增加Z轴分量，Tot[2, 3] += tz，recalculate Tcr by Tcr = Ttr * Tot * Tco。

我们的是手移动到第一个标定目标位置Ttr的Z，

### 4、AXXB

计算X：定义Ransac模型，**误差函数**为min(Ax-xB)，**拟合函数**(根据一组AB计算的X)为四元素法(具体待看)。

优化：使用lm优化X，使用levmar.levmar来实现。

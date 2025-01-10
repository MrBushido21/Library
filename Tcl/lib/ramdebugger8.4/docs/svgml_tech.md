---
title:         SVGML. Convert textual language to SVG  
author:        Ramon Ribo  
email:         ramsan@compassis.com  
affiliation:   http://www.compassis.com  
keywords:      SVG, Markdown, graphics  
date:          2019-11-03  
css:           css/markdown.css  
lang:          en  
---

# Calculating point for tangent arc in path vertex

Command **line** in **svgml** supports all the usual svg **path** subcommands. This
includes the arc definition inside a path: 
```A rx ry x-axis-rotation large-arc-flag sweep-flag x y```. **svgml** includes an
extension to the standard subcommands in order to create an arc in a path vertex
by only providing the radius **r**. 

Syntax is the following: ```AA r x y``` where point ```x y``` will be outside of
the path.

![**Image @img:tan_arc1**.Tangents arc for path vertex](svgml_tech_images/tangent_arc.svg)
  {#img:tan_arc1}

![**Image @img:tan_arc2**. Tangents arc for different paths](svgml_tech_images/tangent_arc2.svg)
  {#img:tan_arc2}

The code for creating these lines is:

~~~~
+svgml1             width:800; height:60%;
+alias              point:p; delta-point:dp; width-height:wh; text:t;
+alias              anchor:a; horizontal-vertical:hv; class:cl; number:n;

line1         line p:2,60,AA,10,45,75,36,20; labels:P~1~,P~2~,P~3~,P~4~; cl:lineMain;
line2         line p:86,20,AA,10,95,75,52,60; labels:P~1~,P~2~,P~3~,P~4~; cl:lineMain;

desc1         text p:25,80; t:sweep-flag=0; cl:text1;
desc2         text p:75,80; t:sweep-flag=1; cl:text1;

.lineMain      stroke-width: 3px; stroke: #1886e7; fill:none;stroke-dasharray: none;
.text1         font-size: 24px; fill: black; font-family: sans-serif;
~~~~

# Calculating tangents and normals from a external point to a curve (bezier or arc)

## Quadratic and cubic Bezier curves definition

- [Quadratic Bézier curves](https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Quadratic_B%C3%A9zier_curves)
- [Cubic Bézier curves](https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Cubic_B%C3%A9zier_curves)

## Elliptical arc 2D definition

An elliptical arc in SVG is defined with the following parameters:

| Parameter    | Description
| ---          | ----------
| $P_0$, $P_1$ | Start and end points
| $r_x$, $r_y$ | the two ellipse radius
| $\varphi$    | angle from the x-axis of the current coordinate system to the x-axis of the ellipse
| $f_A$        | large arc flag, and is 0 if an arc spanning less than or equal to 180 degrees is chosen, or 1 if an arc spanning greater than 180 degrees is chosen
| $f_S$        | sweep flag, and is 0 if the line joining center to arc sweeps through decreasing angles, or 1 if it sweeps through increasing angles
 { .tableALT}

From these parameters, it is possible to obtain the following parameters:

| Parameter      | Description
| ---            | ----------
| $\alpha_0$     | start angle
| $\Delta\alpha$ | angle increment
| $C$            | arc center
 { .tableALT}

Then, the parametric description of the arc is as follows:

$$ f(t)=\begin{bmatrix} \cos(\varphi) & -\sin(\varphi) \\ \sin(\varphi) & \cos(\varphi) \end{bmatrix} \cdot \begin{bmatrix} r_x\cos(\alpha_0+t\Delta \alpha) \\ r_y\sin(\alpha_0+t\Delta \alpha) \end{bmatrix} + \begin{bmatrix} c_x \\ c_y \end{bmatrix} $$

$$ f'(t)=\begin{bmatrix} \cos(\varphi) & -\sin(\varphi) \\ \sin(\varphi) & \cos(\varphi) \end{bmatrix} \cdot \begin{bmatrix} -r_x\cdot\Delta \alpha\sin(\alpha_0+t\Delta \alpha) \\ r_y\cdot\Delta \alpha\cos(\alpha_0+t\Delta \alpha) \end{bmatrix} $$

$$ f''(t)=\begin{bmatrix} \cos(\varphi) & -\sin(\varphi) \\ \sin(\varphi) & \cos(\varphi) \end{bmatrix} \cdot \begin{bmatrix} -r_x\cdot\Delta \alpha^2\cos(\alpha_0+t\Delta \alpha) \\ -r_y\cdot\Delta \alpha^2\sin(\alpha_0+t\Delta \alpha) \end{bmatrix} $$

## Calculating tangents and normals from one point to a curve (bezier or arc)


Given a point $P_0$ and a curve $f=f(t)$ with $t\in[0,1]$, the point where a line
from $P_0$ will intersect the curve and be either tangent or normal to the curve
will be defined as:

### Normal to the curve

Dot product between curve derivative at $t$ and vector $f(t)-P_0$ must be zero.

$$F=f'\cdot fP_0=0$$

### Tangent to the curve

Dot product between curve derivative at $t$ and vector $f(t)-P_0$ must be one, after
normalizing both vectors.

$$\frac{f'\cdot fP_0}{\sqrt{f'\cdot f'}\cdot\sqrt{fP_0\cdot fP_0}}=\pm 1$$

$$F=f'\cdot fP_0\pm\bigg[\sqrt{f'\cdot f'}\cdot\sqrt{fP_0\cdot fP_0}\bigg]=0$$

$$F'=f'' \cdot fP_0+f'\cdot f'\pm\bigg[ \frac{f' \cdot f''}{\sqrt{f' \cdot f'}}\cdot\sqrt{fP_0\cdot fP_0}+\sqrt{f' \cdot f'}\cdot\frac{f \cdot f'-f' \cdot P_0}{\sqrt{fP_0\cdot fP_0}}\bigg]$$

where:

- $f'=\frac{df}{dt}$
- $f''=\frac{d^2f}{dt^2}$
- $fP_0=f-P_0$

The two solutions depending on the sign of $\pm 1$ will give as solutions two possible
tangents to the curve.

The solution to both problems can be obtained by applying a **Newton-Rapson** to the
equation $F(t)=0$ in order to find the value of $t$.

[Newton–Raphson method](https://en.wikipedia.org/wiki/Newton%27s_method)

![Tangents and normals to curves](svgml_tech_images/tangent_normal_to_curve.svg)

~~~~ { svgml="1" file="svgml_tech_images/tangent_arc.svg" }
+svgml1             width:800; height:100%;
+alias              point:p; delta-point:dp; width-height:wh; text:t;
+alias              anchor:a; horizontal-vertical:hv; class:cl; number:n;

lmain          line p:2,60,45,75,36,20; labels:P~1~,P~2~,P~3~; cl:lineMain;

circle1        circle p:25.5,51.5; wh:31,31; cl:lineMain;
circle1.lv     line p:50,50,#lmain,ariste,1,normal; cl:line1;
circle1.lv.s   line p:ariste,1,90; p:ariste,1,90,-10; p:ariste,1,100,-10; cl:line1;
circle1.lv.p   circle p:ariste,1,95,-5; wh:5,5; cl:circle1;
circle1.lv.la  label t:R; p:50,50; a:se; cl:text1;
circle1.lh     line p:50,50,#lmain,ariste,2,normal; cl:line1;
circle1.lr     line p:50,50,#lmain,vertex,2; cl:lineDash;

angle          line p:#lmain,ariste,1,80,A,80,80,0,0,1,#lmain,ariste,2,20; cl:line1arrow;
angle.la       label p:ariste,1,70; t:Ɑ; a:se; cl:text1;

lmain.dimL     dimension p:#circle1.lv,vertex,2; p:vertex,2; t:L; a:ne; cl:text1;
desc           text p:5,80; a:w; t::DESC; a:w; cl:text2;

arrow          region    p:50,40; wh:10,10;
arrow.a        line      p:0,35,60,35,60,0,100,50,60,100,60,65,0,65,z; cl:arrow;

lmain2         line p:52,60,AA,20,95,75,86,20; labels:P~1~,P~2~,P~3~,P~4~; cl:lineMain;

+variables     DESC:L=R/tan(Ɑ/2)\n;
+variables     +DESC:(P~1~P~2~ x P~3~P~2~)~z~ < 0 →  sweep-flag=1\n;
+variables     +DESC:SVG path: A rx ry x-axis-rotation large-arc-flag sweep-flag x y\n;
+variables     +DESC:SVG path: M **P~1,x~** **P~1,y~** A **R** **R** 0 0 **sweep-flag** **P~2,x~** **P~2,y~**\n;
+variables     +DESC:SVG path extension: M **P~1,x~** **P~1,y~** AA **R** **P~2,x~** **P~2,y~**\n;

.lineMain      stroke-width: 3px; stroke: #1886e7; fill:none;stroke-dasharray: none;
.circleMain    stroke-width: 0px; stroke: none; fill:#1886e7;
.line1         stroke-width: 1px; stroke: black; fill:none;stroke-dasharray:none;
.line1arrow    stroke-width: 1px; stroke: black; fill:none;marker-start:url(#TriangleInL);marker-end:url(#TriangleOutL);
.lineDash      stroke-width: 1px; stroke: black; fill:none;stroke-dasharray: 15 3;
.text1         font-size: 24px; fill: black; font-family: sans-serif;
.text2         font-size: 20px; fill: black; font-family: sans-serif;
.circle1       stroke-width: 1px; stroke: black; fill:black;stroke-dasharray:none;
.arrow         stroke: none; fill:#1886e7;
~~~~

~~~~ { svgml="1" file="svgml_tech_images/tangent_arc2.svg" }
+svgml1             width:800; height:60%;
+alias              point:p; delta-point:dp; width-height:wh; text:t;
+alias              anchor:a; horizontal-vertical:hv; class:cl; number:n;

line1         line p:2,60,AA,10,45,75,36,20; labels:P~1~,P~2~,P~3~,P~4~; cl:lineMain;
line2         line p:86,20,AA,10,95,75,52,60; labels:P~1~,P~2~,P~3~,P~4~; cl:lineMain;

desc1         text p:25,80; t:sweep-flag=0; cl:text1;
desc2         text p:75,80; t:sweep-flag=1; cl:text1;

.lineMain      stroke-width: 3px; stroke: #1886e7; fill:none;stroke-dasharray: none;
.text1         font-size: 24px; fill: black; font-family: sans-serif;
~~~~

~~~~           { svgml="1" file="svgml_tech_images/tangent_normal_to_curve.svg" }
+svgml1        width:500; height:500;
+alias         point:p; delta-point:dp; width-height:wh; text:t; operation:o;
+alias         anchor:a; horizontal-vertical:hv; class:cl; number:n;

l1Q            line   p:20,20,Q,100,40,80,80; cl:line1;
l1C            line   p:20,20,C,100,40,40,70,80,80; cl:line1; labels:1;
tangentQ       line   p:85,45,#l1Q,ariste,1,tangent_alt; cl:line1; labels:,Tangent;
tangentC       line   p:85,45,#l1C,ariste,1,tangent; cl:line1; labels:,Tangent;

normalQ        line   p:85,45,#l1Q,ariste,1,normal; cl:line1; labels:,Normal;
normalC        line   p:85,45,#l1C,ariste,1,normal,i,25; cl:line1; labels:,Normal,continuation(i);

arc1           line   p:60,10,A,20,20,0,0,1,80,40; cl:line1; labels:1;

tangentA       line   p:90,30,#arc1,ariste,1,tangent; cl:line1; labels:,Tangent;
normalA        line   p:90,30,#arc1,ariste,1,normal; cl:line1; labels:,Normal;

.line1         stroke:#d44252;fill:none;stroke-width:2px; cl:line1; labels:1;
~~~~







---
title:         svgml manual  
author:        Ramon Ribo  
email:         ramsan@compassis.com  
affiliation:   http://www.compassis.com  
keywords:      svgml, svg, markdown  
date:          2019-12-11  
css:           css/markdown.css  
lang:          en  
---

![Page 1](svgml_images/page1.svg)  {.image100}

<!-- ################################################################################ -->
<!--     ex1 source -->
<!-- ################################################################################ -->

# Example 1. Welcome face {.unnumbered}

~~~~           { svgml="1"  #ex1 display="1" file="svgml_images/ex1.svg" }
+svgml1        width:130; height:170;
+alias         point:p; width-height:wh; text:t;
+alias         anchor:a; class:cl;

face           circle p:50,50; wh:40,40; cl:lines;
face.eye1      circle p:25,35; wh:15,15; cl:lines;
face.eye2      circle p:74,35; wh:15,15; cl:lines;
face.mouth     line   p:25,60,Q,50,90,75,60; cl:lines;
arm1           line   p:50,75; p:15,60; cl:lines;
hand1          line   p:14,59; p:10,50; cl:lines;
hand2          line   p:15,59; p:15,50; cl:lines;
hand3          line   p:17,59; p:20,50; cl:lines;

tborder        line   p:50,30,60,20,90,20; cl:lines1;
text           text   p:75,19; a:s; t:Hey!; cl:bigtext;

.lines         stroke:#d44252;fill:none;stroke-width:3px;
.lines1        stroke:#d44252;fill:none;stroke-width:1px;
.bigtext       font-size: 10px; fill: #d44252; \
               font-family: Montserrat,sans-serif;
~~~~

<!-- ################################################################################ -->
<!--     ex2 source -->
<!-- ################################################################################ -->

# Example 2. Coordinates definition {.unnumbered}

~~~~           { svgml="1"  #ex2 display="1" file="svgml_images/ex2.svg" }
+svgml1        width:130; height:170;
+alias         point:p; width-height:wh; text:t;
+alias         anchor:a; class:cl;

myrect1        rect   p:50,50; wh:20,20; cl:rect1;
myrect2        rect   p:15,15; wh:20,20; cl:rect1;
myrect2.myline line   p:0,0; p:#myrect1,0,100; cl:line1;

.rect1         fill:orange;stroke-width:1px;stroke:red;
.line1         stroke-width:1px;stroke:blue;
~~~~

<!-- ################################################################################ -->
<!--     ex3 source -->
<!-- ################################################################################ -->

# Example 3. Curves {.unnumbered}

~~~~           { svgml="1"  #ex3 display="1" file="svgml_images/ex3.svg" }
+svgml1        width:130; height:170;
+alias         point:p; width-height:wh; class:cl;

quad           region p:70,20; wh:60,33;
quad.q         line   p:0,100,Q,50,0,100,100; cl:line1;

cubic          region p:70,55; wh:60,33;
cubic.c        line   p:0,100,C,40,0,60,0,100,100; cl:line1;

arc            region p:70,75; wh:45,35;
arc.a          line   p:0,100,A,55,55,0,0,1,100,100; cl:line1;

.line1         stroke-width:3px;stroke:orange;fill:none;
~~~~

<!-- ################################################################################ -->
<!--     ex4 source -->
<!-- ################################################################################ -->

# Example 4. Text with borders and arrows {.unnumbered}

~~~~           { svgml="1"  #ex4 display="1" file="svgml_images/ex4.svg" }
+svgml1        width:130; height:170;
+alias         point:p; text:t; anchor:a; class:cl;

text1          text   p:10,10; a:nw; t:Action 1; cl:boxedline;

text2          text   p:10,40; a:nw; t:Action 2; cl:boxedline;
arrow2         line   p:#text1,50,100; p:#text2,50,0; cl:arrow1;

text3          text   p:60,40; a:nw; t:Action 3; cl:boxedlineR;
arrow3         line   p:#text1,100,100; p:#text3,50,0; cl:arrow1;

.boxedline     font-size:6px;fill:#d44252;font-family:Montserrat;\
               border-stroke-width:1px;border-stroke:orange;\
               border-fill:none;
.boxedlineR    font-size:6px;fill:#d44252;font-family:Montserrat;\
               border-stroke-width:1px;border-stroke:orange;\
               border-radius:3px;
.arrow1        stroke-width:1px;stroke:orange;\
               marker-end:url(#TriangleOutL);
~~~~

<!-- ################################################################################ -->
<!--     ex5 source -->
<!-- ################################################################################ -->

# Example 5. References to a curve {.unnumbered}

~~~~           { svgml="1"  #ex5 display="1" file="svgml_images/ex5.svg" }
+svgml1        width:130; height:170;
+alias         point:p; delta-point:dp; text:t; class:cl;width-height:wh;

base           region p:10,10; p:85,85;
base.l1        line   p:M,8,1,C,8,1,48,-2,66,11,C,85,23,101,40,100,74,\
                        C,95,100,78,101,49,99,C,6,95,-1,82,0,61,\
                        C,2,35,21,16,40,19,C,63,22,84,36,84,62,\
                        C,86,90,64,87,48,87,C,41,85,21,85,16,67,\
                        C,9,41,35,27,59,39,C,78,49,77,75,38,70; cl:style1; labels:1;

circle         circle p:#base.l1,ariste,1,50; wh:10,10; cl:styleObject;
rect           rect   p:#l1,ariste,2,75; wh:10,10; cl:styleObject;
image          image  p:#l1,vertex,4; dp:10,10;t:svgml_images/ex1.svg;\
                      cl:styleImage;

.style1        fill:none;stroke:#db4d4c;stroke-width:1px;font-size:12px;
.styleObject   fill:green;stroke:orange;stroke-width:1px;
.styleImage    border-stroke:orange;border-stroke-width:1px;
~~~~

<!-- ################################################################################ -->
<!--     ex6 source -->
<!-- ################################################################################ -->

# Example 6. Tangents and normals to curves {.unnumbered}

~~~~           { svgml="1"  #ex6 display="1" file="svgml_images/ex6.svg" }
+svgml1        width:130; height:170;
+alias         point:p; delta-point:dp; text:t; class:cl;width-height:wh;

arc1           line   p:30,60,A,30,20,0,0,1,90,50; cl:style1;
arc2           line   p:30,60,A,30,20,0,0,0,90,50; cl:style1;

tangent1       line   p:2,50,#arc1,ariste,1,tangent_alt,i,40; cl:style2; labels:1;
tangent2       line   p:2,50,#arc2,ariste,1,tangent_alt,i,40; cl:style2; \
                      labels:,P~2~,P~3~;

.style1        fill:none;stroke:#db4d4c;stroke-width:3px;font-size:12px;
.style2        fill:none;stroke:black;stroke-width:1px;font-size:12px;
~~~~

<!-- ################################################################################ -->
<!--     ex7 source -->
<!-- ################################################################################ -->

# Example 7. Cube and references to cube {.unnumbered}

~~~~           { svgml="1" #ex7 display="1" file="svgml_images/ex7.svg" }
+svgml1        width:130; height:170;
+alias         point:p; delta-point:dp; text:t; class:cl;width-height:wh;

b1.ny2         line   p:face,2,50,50; p:face,2,50,50,30; cl:linearrow;
b1             cube   p:53,70; wh:45,55,10; angles:25deg,45deg;\
                      labels:0; cl:cube;
b1.nx1         line   p:face,3,50,50; p:face,3,50,50,30; cl:linearrow;
b1.nx1.t       label  p:0,100; t:N~x~; anchor:nw; cl:text1;
b1.ny1         line   p:face,4,50,50; p:face,4,50,50,30; cl:linearrow;
b1.ny1.t       label  p:100,100; t:N~y~; dp:0,#b1,10; anchor:ne; cl:text1;
b1.nxy1        line   p:face,6,95,35; p:face,6,95,65; cl:linearrow;
b1.nxy1.t      label  p:100,100; t:N~xy~; anchor:sw; cl:text1;
b1.nxy2        line   p:face,6,5,65; p:face,6,5,35; cl:linearrow;
b1.nxy3        line   p:face,6,35,5; p:face,6,65,5; cl:linearrow;
b1.nxy4        line   p:face,6,65,95; p:face,6,35,95; cl:linearrow;

.cube          stroke-width: 1px; stroke: black; fill:white;
.linearrow     stroke-width: 0.5px; stroke: black;fill:none;\
               marker-end:url(#TriangleOutL);
.text1         font-size: 6px; fill: black; font-family: sans-serif;
~~~~

<!-- ################################################################################ -->
<!--     ex8 source -->
<!-- ################################################################################ -->

# Example 8. Copy drawing parts {.unnumbered}

~~~~           { svgml="1" #ex8 display="1" file="svgml_images/ex8.svg" }
+svgml1        width:130; height:170;
+alias         point:p; delta-point:dp; text:t; class:cl;anchor:a;
+alias         width-height:wh;horizontal-vertical:hv;

R1             region p:60,45; wh:40,35;
R1.shell1      line   p:35,100,Q,45,55; p:100,40; p:60,0,Q,20,10; p:0,55; \
                      p:Z; cl:lineDash;
R1.shell1.desc label  p:ariste,1,55; dp:40,40; t:shell midplane; a:n; cl:text1;
R1.shell1.cp1  copy   p:35,100; dp:-1,-5; p:100,40; dp:0,-6; p:60,0; \
                      dp:0,-6; p:0,55; dp:-1,-5; connect:points; cl:line1;
R1.shell1.cp2  copy   p:35,100; dp:1,5; p:100,40; dp:0,6; p:60,0; \
                      dp:0,6; p:0,55; dp:1,5;  connect:points; cl:line1;
dimthickness   dimension p:#cp1,vertex,2; p:#cp2,vertex,2; hv:v; a:w; \
                      t:thickness; cl:text1;
R1.shell1.shell2 copy   dp:#R1,0,110; cl:lineMain;

.lineDash      stroke-width: 1px; stroke: #1886e7; fill:none;stroke-dasharray: 15 3;
.lineMain      stroke-width: 1px; stroke: #1886e7; fill:none;stroke-dasharray: none;
.line1         stroke-width: 0.1px; stroke: black; fill:none;stroke-dasharray:none;
.text1         font-size: 4px; fill: black; font-family: sans-serif;stroke-width:0.3px;
~~~~

<!-- ################################################################################ -->
<!--     page1 source -->
<!-- ################################################################################ -->

# Main documentation page {.unnumbered}

~~~~           { svgml="1" display="1" file="svgml_images/page1.svg" }
+svgml1        width:595; height:842;
+alias         point:p; delta-point:dp; width-height:wh; text:t; operation:o;
+alias         anchor:a; horizontal-vertical:hv; class:cl; number:n;

title          text   p:50,1; a:n; t:SVGML; cl:title1;
subtitle       text   p:50,3.5; a:n; t:“Creating **SVG** drawings from *markdown*”; cl:title2;

background     rect   p:4,6; p:96,98; cl:background;
copyright      text   p:50,98.5; a:n; cl:bigtext; \
                      t:©Ramon Ribó 2020 - http://www.compassis.com/ramdebugger;
#page           text   p:96,98.5; a:ne; t:1/4; cl:bigtext;

#################################################################################
#    example 1
#################################################################################

ex1            rect   p::marginH,:marginV; wh::boxwidth,:boxheight; a:nw; \
                      cl:bgexample;
ex1.t          text   p:3,20; a:nw; cl:mytext; t::ex1;

ex1.img        image  p:50,0; p:100,100; t::ex1; a:nsew; 

#################################################################################
#    example 2
#################################################################################

ex2            rect   p:100-:marginH,:marginV; wh::boxwidth,:boxheight; a:ne; \
                      cl:bgexample;

ex2.t1         text   p:2,30;  a:nw; cl:mytextB; t:\
                      Coordinates are defined from **0** to **100**\n\
                      related to:\n\
                      - the global drawing (if no parent)\n\
                      - the parent **bounding box**\n\
                      - the **reference** bounding box (#myrect1);
ex2.t          text   p:3,95; a:sw; cl:mytext; t::ex2;
ex2.img        image  p:55,5; p:95,95; t::ex2; a:nsew;

ex2.img.c2v    line   p:98,0; p:100,0; cl:lines1black;
ex2.img.c2v.c  copy   dp:#ex2.img,0,2; n:50; cl:lines1black;
ex2.img.c1v    line   p:96,0; p:100,0; cl:lines1black;
ex2.img.c1v.c  copy   dp:#ex2.img,0,10; n:9; cl:lines1black;
ex2.img.t1v    text   p:100,0; t:0; a:w; cl:mytextM;
ex2.img.t2v    text   p:102,99; t:100; a:w; cl:mytextM;

ex2.img.c2h    line   p:0,98; p:0,100; cl:lines1black;
ex2.img.c2h.c  copy   dp:#ex2.img,2,0; n:50; cl:lines1black;
ex2.img.c1h    line   p:0,96; p:0,100; cl:lines1black;
ex2.img.c1h.c  copy   dp:#ex2.img,10,0; n:9; cl:lines1black;
ex2.img.t1h    text   p:0,100; t:0; a:n; cl:mytextM;
ex2.img.t2h    text   p:100,101; t:100; a:ne; cl:mytextM;

ex2.img.lab1   label  p:50,50; t:myrect1; cl:mytextM;
ex2.img.lab2   label  p:15,15; t:myrect2; cl:mytextM;

#################################################################################
#    example 3
#################################################################################

ex3            rect   p::marginH,:marginV+:boxheight+:separationV; \
                      wh::boxwidth,:boxheight; a:nw; cl:bgexample;

ex3.t1         text   p:2,25;  a:nw; cl:mytextB; t:\
                      Different types of curves can be displayed\n\
                      Follow **svg** manual for details\n\
                      numbers inside a point are always\n\
                      separated by commas;
ex3.t          text   p:3,95; a:sw; cl:mytext; t::ex3;
ex3.img        image  p:60,5; p:95,95; t::ex3; a:nsew;

ex3.img.quad.n text   p:-10,20; t:Cuadratic\ncurve; a:ne; cl:textblackM8;
ex3.img.quad.l line   p:0,100,L,50,0,100,100; cl:line2; labels:P~1~,P~2~,P~3~;

ex3.img.cubic.n text   p:-10,20; t:Cubic\ncurve; a:ne; cl:textblackM8;
ex3.img.cubic.l line   p:0,100,L,40,0,L,60,0,100,100; cl:line2; \
                      labels:P~1~,P~2~,P~3~,P~4~;

ex3.img.arc.n  text   p:#ex3.img.quad,-10,#ex3.img.arc,70; t:Arc\ncurve; \
                      a:ne; cl:textblackM8;
ex3.img.arc.l  line   p:0,100,L,100,100; cl:line2; labels:P~1~,P~2~;
ex3.img.arc.lb label  p:#arc.a,ariste,1,50; dp:0,45; a:nw; \
                      t:r=55; cl:textblackM6;

#################################################################################
#    example 4
#################################################################################

ex4            rect   p:100-:marginH,:marginV+:boxheight+:separationV; \
                      wh::boxwidth,:boxheight; a:ne; cl:bgexample;
ex4.t1         text   p:2,15;  a:nw; cl:mytextB; t:\
                      Text with borders, rectangles\n\
                      and rounded;
ex4.t          text   p:3,95; a:sw; cl:mytext; t::ex4;
ex4.img        image  p:60,5; p:95,95; t::ex4; a:nsew;

#################################################################################
#    example 5
#################################################################################

ex5            rect   p::marginH,:marginV+2*:boxheight+2*:separationV; \
                      wh::boxwidth,:boxheight; a:nw; cl:bgexample;

ex5.t1         text   p:2,15;  a:nw; cl:mytextB; t:\
                      To reference parts of another curve:\n\
                      - **#ref,vertex,1\3B** vertex 1\n\
                      - **#ref,ariste,2,60\3B** ariste 2,3 60%;
ex5.t          text   p:3,95; a:sw; cl:mytext; t::ex5;
ex5.img        image  p:60,5; p:95,95; t::ex5; a:nsew;

#################################################################################
#    example 6
#################################################################################

ex6            rect    p:100-:marginH,:marginV+2*:boxheight+2*:separationV; \
                       wh::boxwidth,:boxheight; a:ne; cl:bgexample;

ex6.t1         text   p:2,15;  a:nw; cl:mytextB; t:\
                      tangent or normal to another curve:\n\
                      - **#ref,ariste,1,tangent\3B**\n\
                      - **#ref,ariste,1,tangent_alt\3B**\n\
                      - **#ref,ariste,1,normal\3B**\n\
                      - **i** segment continuation with the same slope;
ex6.t          text   p:3,95; a:sw; cl:mytext; t::ex6;
ex6.img        image  p:60,5; p:95,95; t::ex6; a:nsew;

#################################################################################
#    example 7
#################################################################################

ex7            rect    p::marginH,:marginV+3*:boxheight+3*:separationV; \
                       wh::boxwidth,:boxheight; a:nw; cl:bgexample;

ex7.t1         text   p:1,5;  a:nw; cl:mytextB; t:\
                      Drawing a **projected cube**\n\
                      - **angles** are the projection angles (XY,Z)\n\
                      - **labels** can be: 0,1,vertex,ariste,face,all;

ex7.sep        line   p:50.5,2; p:50.5,25; cl:sep;

ex7.t2         text   p:51,5;  a:nw; cl:mytextB; t:\
                      References to **cube faces**\n\
                      - p:face,**#face,x,y,z?\3B** face coordinates\n\
                      - **x,y** inside face,  **z** orthogonal to face\n\
                        use **labels:face** to view **#face**;

ex7.t          text   p:3,95; a:sw; cl:mytext; t::ex7;
ex7.img        image  p:60,5; p:95,95; t::ex7; a:nsew;

#################################################################################
#    example 8
#################################################################################

ex8           rect    p:100-:marginH,:marginV+3*:boxheight+3*:separationV; \
                       wh::boxwidth,:boxheight; a:ne; cl:bgexample;

ex8.t1         text   p:1,5;  a:nw; cl:mytextB; t:\
                      **Copy entities**: by translation simple or by a set\n\
                      of points and increments.\n\
                      - Make multiple copies with **number**\n\
                      - Connection entities with connect:**points|lines**\3B\n\
                      - Copies *parent* or from:**ref1**,**ref2**\3B;

ex8.sep        line   p:59.5,2; p:59.5,25; cl:sep;

ex8.t2         text   p:60,5;  a:nw; cl:mytextB; t:\
                      -\t**dimension**: to display lengths\n\
                      \tof entities\n\
                      -\t**label**: to give name to entities;

ex8.t          text   p:3,95; a:sw; cl:mytext; t::ex8;
ex8.img        image  p:60,5; p:95,95; t::ex8; a:nsew;

#################################################################################
#   variables for creating the examples boxes 
#################################################################################

+variables     boxwidth:43;
+variables     boxheight:20;
+variables     marginH:6;
+variables     marginV:9;
+variables     separationV:2;

<!-- ################################################################################ -->
<!--     styles -->
<!-- ################################################################################ -->

.title1        font-size: 24px; fill: #d44252; font-family: Montserrat,sans-serif;
.title2        font-size: 16px; fill: #d44252; font-family: Montserrat,sans-serif;
.background    fill:#d44252;stroke:none;border-radius:0px;
.bgexample     fill:white;stroke:none;fill-opacity:.70; border-radius:6px;
.mytextB       font-size: 6px; fill: black; font-family: Montserrat,sans-serif;
.mytextM       font-size: 4px; fill: black; font-family: Montserrat,sans-serif;
.mytext        font-size: 4px; fill: black; font-family: Montserrat,sans-serif;\
               border-stroke-width:1.5px;border-stroke:none none none orange;\
               border-fill: #ffe3e6;
.bigtext       font-size: 10px; fill: #d44252; font-family: Montserrat,sans-serif;
.textblackM8   font-size: 8px; fill: black; font-family: Montserrat,sans-serif;
.textblackM6   font-size: 6px; fill: black; font-family: Montserrat,sans-serif; \
               stroke-width:0.4px;
.lines         stroke:#d44252;fill:none;stroke-width:3px;
.lines1        stroke:#d44252;fill:none;stroke-width:1px;
.line2         stroke-width:0.3px;stroke:black;fill:none;stroke-dasharray: 15 3;\
               font-size: 6px; font-family: Montserrat,sans-serif;
.lines1black   stroke:black;fill:none;stroke-width:0.2px;
.rounded       fill:#d44252;border-radius:3px;
.dims1         stroke:#d44252;fill:none;stroke-width:1px;font-size: 4px;\
               font-family: Montserrat,sans-serif;
.sep           stroke:grey;stroke-width:0.2px;
.___           fill:red;
.__            fill:green;
._             fill:magenta;
.***           fill:blue;
~~~~
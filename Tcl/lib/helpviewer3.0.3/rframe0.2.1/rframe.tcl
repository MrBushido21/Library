# rframe.tcl ---
# -------------------------------------------------------------------------
#  Copyright (c) 2009  Johann Oberdorfer, johann.oberdorfer@gmail.com
#  This source file is distributed under the BSD license.
#
#  Thank's to Bryan Oakley, who wrote the article http://wiki.tcl.tk/20152
#  in 2007 which was very straight forward at a time - where tile was
#  in an early developement stage too. A few years later, I picked up the
#  idea and came along with this approach.
# -------------------------------------------------------------------------
#
# PURPOSE:
#   rfame -- Implements a ttk frame widget with customized borders.
# -------------------------------------------------------------------------

# Revision history:
# 17-04-11: expand true added

package require Tk
package require tile

package provide rframe 0.2

set images(rframe_active) [image create photo -data {
iVBORw0KGgoAAAANSUhEUgAAAMgAAACgCAYAAABJ/yOpAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAAEbAAABGwAcgn9VQAAAAGYktHRAD/AP8A/6C9p5MAAAAHdElNRQfhAR0J
Dhri7ysOAAASI0lEQVR4Xu2diZMcV33Hv91z7+7srqTVZcmSLAtsLHzIlp2IHM4BsV0hlZRxJaZM
irhIfFChYkgwoVKAg6FwymBSBWUFk0ARAjHECQ4pxwdOjDEWMhaSTx3W7kpa72rv1c7Mzn10ft83
M85qtdv/wHw/VbM70/1ev/P7ju5fv+e95zM/DTwAnv2JxXzki3Uk7H8i5uHRT+5Brd5ANOK/9Z+8
fCKDO/ceQF9PCr7voVRpuOPRiIfdO/rw+Vt2ut9tFko19CSjePzgBD73vcPo604iGvVgXlGuBsjm
S7jt+gvxwd/c6twzLN9rhuXbvy88cgzPvj6LqMUrCAI06vYJ7LrFCr5462XYc9Hqs+JXqtaRjEXw
/gdexEymgkTc4l/jNS2u1QbK5RKe/cJvoWYXiUciLow243Ml3PLlA0gkIi4chkd/1Vod561J4dt3
7XbuFodHDr+Zw5999QDW9idRrASoWBxS8Qjy5Rp+49K1+Nub39Fy2aQdx399bhQPPXUKKctvS5KD
5VG0fLntd7bi/b+2+S23i/nMw0fw41enkYxHLbw6YhaXrqSPuWwJD95xJS7f1tdyCTSseNpp/NBX
D2JstuTy3uWlheZbuZXLdXzno7uxcXWy6dCgv0q97vLoV+9+Cr3pbotj0z2pWV6uTsfwvb+65qww
2vF98fgc7vqnV9CTirvw6M+zvKS/a3euwSdvusj5I43g//PzW8+cwkNPDKG3VU9Y1rUa60kRn755
J264cgPOLJTR15U4q+w+9d3DeP7IrIXhI27+CMPM5Kv42h1XYOeWXndsKTfcuw91K+uIuY2Zv4rV
Z/vp6rPf1x1DuiuCqVwVr1jFn5wvWWFnMTJTdJ7bkV5cGch4tuHcHR7J4cTkAoYnFnD89ALmLTJL
oTgIz03l6njV/BwazuLgUAZHxxYwkakhW6g7N4RhMeHtxLMCHBnL4cWj03jtZNPPMfs9PDqDdqwW
x69dmaYyZefvuLk/NV3A6xbfiTMlnJwuOfd0tziDCSvIZLaME+MLGLTPySn6y2FwsoBx89tmaX5k
ClWcmMjgwGDG4pbFlF2D4dF/zs4tpR1HCvfwqVkXT6aLH37nMZ4jS8VBeE1em2HN5coYmsjh1ZM5
DI3NW6VrS63J4jQyHw6PmlsrgyFLE9PItDLNi8VB6K+dRyNzNef36Kilycp62Mqa8Vwo1t5y26Yd
37IJgWXEsmK6WHYsQ/pjmRL642dxfrIusE7QD9NEf7zGXD54q36t6jlbHGSG5WZ5wrpIv6yf9MsG
ocoavwJnFioYsbSdmi7ihWPzmF6oWsPDxtgaq/d+7nnTLnD3778Nl5yfRsUKpTsZc4lb359oXmEZ
Rqbz6O2KW0tqraW1rvGotbjWHPCi61edndGLecMydlV31PmLmR8SWAzW9q3sZ2K+iGK54Vpk5iNb
CPopVICta1f2NzpTcD3GmnTCxTFiOcpWM2OFumNDd8vVuVBYdFe2QkwlKO6gFV8fA70r5wkzuCvO
VtK3XrNqDUPM9Z5dCR/rQtI3k62gUK6au5j73f4+0Bt3v5djKlMydw3X+DCsNT1xV+mqDQ+bVq8c
R1YWpo0jBJZVyfwkLF/Zsq/rW9kfxZiyStNlbrPFKtKWNjYCCcuT89d2tVydyylrjKyavFVm1vG6
eKYsTzb0p1quzmXa0kc/hP7ImXwNbz+vx31fDjYa7L3oj3UxbkJlueUsvhesX7m8T88VLW1R1+tH
LT0vDc/j/kePW8cRg3fdZ5934X/xT96JS7cu3wUJ0UkcMoH8zb8ctmG1Dcs5NswuMwQQolOJWy9S
tJFH2kY6fq910QPWtcZaEy8hOh3egEnFbB5sw05/OlNBqVxz41ghRBPOXWayVfgzC2VM2KS0fbtN
iE6nUgswzpsglRq8gLc0hBDLsuROshBiMRKIECFIIEKEIIEIEYIEIkQIEogQIXhb/vTxgAZ9//wX
V+G6Xetbh4XoXJ48NIkP/P0v3Gsf/js2p3HV9v5Qy10hOglq4eod/bh0Sxq+H/Hdizo0cxdCNLXA
x+eebz1Igwb6RmqZl3KE6ETaWqA2/O5UFA2TCz9CCL7+29QDteGfni1hoVR3XYoQgm8wwmmC2vB3
XdCHPRf1o7v13rgQnQ61QE1QG7LmFSIEPSgUIgQJRIgQJBAhQpBAhAhBAhEiBO8H+8cCzwN+b/fG
5iJZQnQ4XLr1vw6Mu5U4ve23Pxk06jU89Oe78Z7L17WcCNG5/OjlKdy+9yX33b9sWxrbNqSxUda8
Qjioha1ru3Dp1jTnIB7SXVGUZc0rhIPLjnYnI4jSmpfLLFZr3AejdVaIDocz8brNQ7gjgM99E7hs
PJf2F0LAaYGaoDY4T3f7bnCfCCFEc88UaoLa8P73lakg4nu4cns/elKy6BWCu2YdHJ53wyxZ8woR
giYeQoQggQgRggQiRAgSiBAheAvcsd5r7m3Nu1lCdDq8e1WuNhcy8T7y9ZeDRNTDh969FRdv1jbQ
QhwdzeLrPzqJWt2GWPuOzuL5I3OYW9AmnkIQauG5w3PYd2wW/vkDKaQSEaT1kFAIB7UwkI5j4+oU
35Hy3MbpQog2Huo2AYnanNynmTvfKCxXZe4uBKGFu83T3X8/V6ggW6wiX5axohAkU6ihUq0jk6/A
X9ebwIbeGFb1xFqnhehsVqdjNgeJgtrw8qVaUG80bGIigQjRJmejKrdog6x5hVgZ3b4SIgQJRIgQ
JBAhQpBAhAjBe/VUxk3Stwyk0NulO1lCZAtVjMwU3Xdvzyd+TKNefOnWndhz0Rp3UIhO5mfHZvGX
33zdvgXwe1NRJGM+uhMyVhSCUAvUBLXhx6Ie+J6UHocI0YRaoCacNqo1IG5qqdUlECEItUBNUBt+
1FRSqTYgW14hmlAL1AS14c/lypjOVVBXDyKEg1qgJqgN797vHw3ippSb9mzC9g3dLSdCdC7DE3k8
8rMxVGpaelSIUPQkXYgQJBAhQpBAhAhBAhEiBAlEiBC8R184HUQ84Oq3rcL6/mTrsBCdy+R8CfuP
nUEjCOBd8dH/CRqNAHvv2IV3Xby65USIzmXf0TncsfclbuAJ/7zVSWxYlURXItI6LURn05OMYF1/
AhtNFz4fq3PbA64iJ4RorqjI1XidVW/EJiBR+2hvECGaeJ6HRNwHteGXqg1kCnU3IRFCNDfQyZkm
qA3fC6wHse5E74MI0YQLuUdsSk5teP99YCLwTCBXbOtzk3UhOp3Tc0W8OpJFo06RyJpXiBXRk3Qh
QpBAhAhBAhEiBAlEiBC8uVw5iEZ87XIrxCK4/CjvXnkf+8YrQSzq447rtmHbOi3aIMSJyTweeuoE
qvUA/vNHZ/HkoUmMnym3TgvR2YyfKZkmpvCTw7Pw16TjWNubQFdc1rxCEE43BkwT6/oS8Gli4nue
G28JIWjFi5aFu2mDi8aZPtxivUKIJpRDzAZV/nS2iplsBeVqvXlGiA6HWpgyTVAb/jU7+nHVjj5s
X687WEIQamG3aYLa8MZmC+6d9M0DXa3TQojRmQJ8m3fImleIEGRqIkQIEogQIUggQoQggQgRgvfT
I9NB1Pdx9Y5+m7VLL0I0Gg38fHAe9XoDkblNN96z7405XLI5rbV5hTBeG8nivn9/A/vfmIefK9Uw
NltCsaKVFYUgC6aJkZkiZnIV+H1dUfSloujW2rxCOHoSUfR3x7E6HYVfsp6DTwy5ipwQAk4LEZuO
VyoBfD5Hp7l7VOa8Qji4VjXteWsNE8jwRA6D4xkUKrLmFYIUTQtDp+dBbXjffPpkEAQN3LhnM/q6
Yy0nQnQumXwVP9g/Zj2JL2NFIcLQk0EhQpBAhAhBAhEiBAlEiBAkECFC8O55+EjAByN/9CubsGNj
T+uwEJ3L4PgCvvvcKLhWg//Mq9N47MAE5vPV1mkhOhtq4YmDk6A2fC5cTUNF7uwphGjucktNxGMR
Z6eIWMRHglvdCiGcFqgJasPn/KNco0Vv66wQHQ61QE1QG34Az33xuBe0EMJpgZqgNvyTU3mcnCqg
UK61TgvR2VAL1AS14Y3OFJy14treOBJczlqIDoeLV09nK26Fd1nzChGCJh5ChCCBCBGCBCJECBKI
ECFIIEKsQL3RgPe++/Y7a95P3Ph27Nre3zolROdyaHge9//nIMrlOvzZfBWjsyUZKwrRglo4MZHH
fLEKPxn1ke6OSSBCtKAWuCQvH5z7Thj1pmGWEKK5siLVUKMRbzzmw4s0zXuFEM3XP6gJasMvlGoo
lmtoyOJECAe1QE1QG353MoYe+0gfQjShFqgJasOr8810w1kuepqHCEH73XZ/IWteIULQzFyIECQQ
IUKQQIQIQQIRIgRvcHwh4JJYW9d1tw4JIYYnC+5ulvdLH38mqDWAB259J35950DrtBCdy09en8Fd
/3gIiXgMfn9PDKm474yzhBBwWuhPp9CVNIHwB9chrda1T7oQpGJDKi4/OtAThT+/UEMs5ptAWmeF
6HDaj86zpXrTmrdabaAnqUXjhCApG1ERml75Y7MlzOYqmLOPEAJOCzPZMibmSvC+8tigM8f68A0X
IsL13oXocPgS4YOPD7keRMaKQoSgJ+lChCCBCBGCBCJECBKIECFIIEKE4P3Dk8MB1//5wLVb0Ncd
ax0WorP58g+H0JX0ERlf/wf3HBrOYOeWXmxfL5N3IZ5+eQoP/PA4Dg5n4W9fn0JvKop1vfHWaSE6
mzXpmI2m4ti6LgW/Wg8Qj0W05I8QLaJ+c6XRoBHAp2kvd4Su1mXOKwSpmTCoiTLX5uWycbGoh9Xp
ROu0EJ0Nt0T3Ix6oDe+9n98XdMV9U4yPYqXmTH1LlQbW9yfwtTt3tbyczcGheXz2+0dRs+FZ0oZn
0ShQLNe5SDx27+jDPTdf0nJ5Nk+/PIkHHz+BuvmLRiMmTNh3U6x5vOldm3DLtee3XJ7N3seH8cSh
Sfedw8GGhUO7ShqVfeoPL8au7X3u3FJue/AgRqZL1l16SHdFkC/VEWXXGQT4j7/+5Zarc3nf372A
crXh0saetVwN0J2MYJuNSb9062UtV2fz+kgGH//WYbdCZdLy07cha6lSh/XWePfla/GR393RdLiE
R/aN4tvPjsHaKCTizWFuuRKgZoXzx9dusnzZ7I4t5SuPDVp+Tru8SMYtTyxNLDca1t3/wUuwc8vy
efKxb7yCU1NFFCxuXVbWXMd8oVRD2uah/3b3NS1X53LjffvdMJxlxbzIFeqWNwG2rE3ioQ9f2XJ1
Nrz5c6/VExrBsrIxLyqtF4+u37Ued96w3X1fyneefdPyxfKEZWW/6Yf+uyydt19/AX77srVNh0u4
5+HDODCYsfCaJuu1GlAyv1yt/dNWT668cPkNom7fewiT82VXbkWrI8kE365tWB5ZDzIxV3Yb6Byf
yOPUdBFH3lzA0dEcXhvJNn0vw5aBFI6O5TA2W8SJ6TxeO7Xg/J6es4wvr/xmYtlK/dCJLEbmSnhz
Nu/COn56Aa+cylphrfxI5ky+ZhW96MIYP1Oy+Oadv18MzmDAJlQrMZOrYipTMv8VHB5rpm/I0sk4
hEE3TNvJmaafyfmSOzY0UWy5OBfeIj9meTK7UMLgeDN+mWLV+WdlWom4tS4vDc1geLrg4sgPv/MY
z60Er8lrMwyGxTAZNuMQdrv+tOU9r3/SPkwT08g84jXCeOlk1rlnmIwj85T+mMcrwbJhGfHaLDOW
Hf2zLFmmK8G6wDpBf0OTeUxaOKetDH5uDXPYVIB1j3WQYbBOsm6yHFlXWWdXgnX92OlmPX7T4viG
uT9t/6kNb+/jQ86ed/EcnS1F1FS/dX2Xa+2XwtbqxGTBteJsHdqb73DsljKVb123vD/2MswkKppn
W8sCW8viodtUO7DMnbS4Na2jlshMoebixBaTceWHI8VNqxNuo5OlRCyMIUs0V1lla7549Xp+3WZp
4/GlMA1vWuUh7XyJWW9XrbE38LF9w7lpY1hla5G5EgbjGIv6rqV1PZ3pni3TxlXLF1AmX3Vp4354
i4mYR74OvVJlHz9TdD1GOwy2tlUbMzP+2y1tCSuH5eI52BICJ6F8zXpx2V+wwm1+XnPYxMGeuE07
T9kDXXhetwuLvxfnKee3bHxZ2gyHH8aV12PaNq9JmZuz40hmshXkuePAovrBq3LEsnFV8q0XmhbD
tJ2aKtgoyHoMc++O2X/WTV7mghXK2/mzcmOcFhu286vnAf8H1+6tsfdkhbUAAAAASUVORK5CYII=
}]
set images(rframe_normal) [image create photo -data {
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
}]


# -------------------------------------------------------------------------
# -------------------------------------------------------------------------

namespace eval ::rframe {
	variable wLocals
	
	array set wLocals [array get images]

	ttk::style element create RoundedFrame image \
			[list $wLocals(rframe_normal) focus $wLocals(rframe_active)] \
			-border 4 -width 200 -height 160 -sticky nsew
				
	::ttk::style layout \
			RoundedFrame { RoundedFrame -sticky nsew }
}


proc ::rframe::rframe {w {bg ""} } {
	variable wLocals

	if {$bg == ""} {
		# set bg "#DFECFF"
		set bg "white"
	}

	# avoid problems under OSX:
	if {[catch {ttk::style layout RoundedFrame}] != 0} {

		ttk::style element create RoundedFrame image \
			[list $wLocals(rframe_normal) focus $wLocals(rframe_active)] \
			-border 4 -width 200 -height 160 -sticky nsew
				
		::ttk::style layout \
			RoundedFrame { RoundedFrame -sticky nsew }
	}
	
	
	ttk::style configure RoundedFrame \
			-background $bg
	
	# 17-04-11: expand true added
	set f [eval ttk::frame $w -style RoundedFrame]
	pack $f -side top -fill both -padx 4 -pady 4 -expand true
	
  	# container frames to ensure required padding
	# to match with rounded frame icons...
	
	# 17-12-11: expand true added
	set f1 [frame $w.fpad1 -relief flat -bg $bg]
	pack $f1 -side top -fill both -padx 4 -pady 4 -expand true
	
	set f2 [frame $f1.f2 -relief flat -bg $bg]

	# binding for rframe:
	bind $f2 <Enter> [list $f state focus]
	bind $f2 <Leave> [list $f state !focus]

	return $f2
}

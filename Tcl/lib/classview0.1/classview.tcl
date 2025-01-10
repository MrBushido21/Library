# TODO: display method chaining and mixin decorations?
# TODO: code syntax highlighting?
# TODO: check why ::oo::Obj124 is having its own namespace as a child of itself?
package require Tk
package require base64

namespace eval ::classview {

proc visual_push btn {
	foreach event {Enter ButtonPress-1 ButtonRelease-1 Leave} {
		# Catch possible errors in case when the button is already destroyed.
		catch { event generate $btn <$event> }
		if { $event eq {ButtonPress-1} } {
			update idletasks
			after 100
		}
	}
}

proc recursive_bind {root widget binding} {
	set level [info level]
	set prc [lindex [info level $level] 0]
	foreach child [winfo children $widget] {
		set class [winfo class $child]
		if {$class in {TCheckbutton TRadiobutton TButton Label}} {
			set underlined [$child cget -underline]
			if {$underlined != -1} {
				set letter [string tolower [string index [$child cget -text] $underlined]]
				switch $class {
					{TButton} {set action [namespace code [list visual_push $child]]}
					{Label}   {
						set coupling [winfo parent $child].e[string range [winfo name $child] 1 end]
						set action [expr {[winfo exists $coupling] && [winfo class $coupling] eq {TEntry} ? [list focus $coupling] : {}}]
					}
					default   {set action [list $child invoke]}
				}
				foreach key [list $letter [string toupper $letter]] {
					set ascii [scan $key %c]
					if {$ascii >= 48 && $ascii <= 122} {
						bind $root <Alt-$key> [expr {$binding ? $action : {}}]
					} else {
						$child configure -underline -1
					}
				}
			}
		} elseif {$class in {TLabelframe Frame}} {
			$prc $root $child $binding
		}
	}
}

variable show_text 0
variable entity {}

variable GUI

set GUI(win)      .classview
set GUI(dpi)      [expr int((25.4*[winfo screenwidth .])/[winfo screenmmwidth .])]
set GUI(high)     [expr {([tk scaling] > 1.8) || ($GUI(dpi) > 140)}]
set GUI(pad)      [expr {$GUI(high) ? 5 : 2}]

if {$GUI(high)} {::ttk::style configure Treeview -rowheight 40}

if {[winfo exists $GUI(win)]} {destroy $GUI(win)}
toplevel $GUI(win)

set GUI(pane)     [::ttk::panedwindow $GUI(win).pane -orient vertical]
set GUI(top)      [::ttk::frame $GUI(pane).top]
set GUI(bottom)   [::ttk::frame $GUI(pane).bottom]
set GUI(tree)     [::ttk::treeview $GUI(top).tree -columns brief]
set GUI(treevs)   [::ttk::scrollbar $GUI(top).vscroll -orient vert -command [namespace code [list $GUI(tree) yview]]]
set GUI(text)     [text $GUI(bottom).text -height 10 -wrap none]
set GUI(textvs)   [::ttk::scrollbar $GUI(bottom).vscroll -orient vert -command [namespace code [list $GUI(text) yview]]]
set GUI(texths)   [::ttk::scrollbar $GUI(bottom).hscroll -orient horiz -command [namespace code [list $GUI(text) xview]]]
set GUI(toolbar)  [frame $GUI(win).toolbar]
set GUI(chktext)  [::ttk::checkbutton $GUI(toolbar).chktext   -text {Text pane} -underline 0\
	-variable [namespace which -variable show_text] -command [namespace code switch_pane]]
set GUI(lobject)  [label $GUI(toolbar).lobject -text {Namespace/Class/Object:} -underline 0]
set GUI(eobject)   [::ttk::entry $GUI(toolbar).eobject -textvar [namespace which -variable entity]]
variable toolbar [list $GUI(lobject) $GUI(eobject)]
foreach tag {show demo clear} {
	set GUI(tbb.$tag) [::ttk::button $GUI(toolbar).btn$tag -text [string totitle $tag]\
		-command [namespace code tbb.$tag] -underline 0]
	lappend toolbar $GUI(tbb.$tag)
}

# Configure treeview appearance and events:
variable tag
variable value

foreach tag {class object mixin filter namespace variable method array novariable constructor destructor procedure command window} {
	$GUI(tree) tag configure $tag -image ::classview::img::$tag
}
foreach tag {tree text} {$GUI($tag) configure -yscrollcommand [namespace code [list $GUI(${tag}vs) set]]}
foreach tag {text} {$GUI($tag) configure -xscrollcommand [namespace code [list $GUI(${tag}hs) set]]}
foreach {tag value} {#0 {Class/Object hierarchy} brief {Miscellaneous info}} {$GUI(tree) heading $tag -text $value -anchor w}
$GUI(tree) column #0 -stretch no -width 280
#foreach event {Return Double-Button-1} {bind $GUI(tree) <$event> [list showFile $filelist]}
bind $GUI(tree) <<TreeviewSelect>> [namespace code change_selection]
bind $GUI(tree) <<TreeviewOpen>>   [namespace code {tree_keypress %W Return}]
bind $GUI(tree) <KeyRelease>       [namespace code {tree_keypress %W %K}]
bind $GUI(text) <Control-x>        [namespace code {text_eval %W}]

pack $GUI(top)    -side top   -fill both -expand yes
pack $GUI(tree)   -side left  -fill both -expand yes
pack $GUI(treevs) -side right -fill y

grid $GUI(text)   -column 0 -row 0 -sticky nswe
grid $GUI(textvs) -column 1 -row 0 -sticky ns
grid $GUI(texths) -column 0 -row 1 -sticky we
grid columnconfigure $GUI(bottom) 0 -weight 1
grid rowconfigure    $GUI(bottom) 0 -weight 1

foreach tag {top bottom} {$GUI(pane) add $GUI($tag)}
lappend toolbar $GUI(chktext)
pack {*}$toolbar   -side left -anchor w -padx $GUI(pad) -pady $GUI(pad)
pack $GUI(toolbar) -side top -fill x
pack $GUI(pane)    -side top -fill both -expand yes

# Create icons.
if {$GUI(high)} {
	set IMAGE(array) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAmklEQVR4nOXSQQ6AIAxEUY/uzXGlIUjbsc4IRJJuCOQ/otu24CrO6KOl7OYoMGEUwOTjmbABGRPPIqjxDGIoQBJHEdI4gvg3ALqoREBxFoIGqPfbM/WeFOCFKQDr1VYA/Z/WArTzGSDaZwK6CAXAirufgTlTA+SIKC5FoPEpAHTE0zgVkY1fiCzkvPsmfoNEmPocK+xiOrPeOgC7yzJb6hcPlAAAAABJRU5ErkJggg==}
	set IMAGE(class) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAr0lEQVR4nO2USwrAIAwFc/TevN21VvIz5qUKVdyEwEyeItGG6zQOFnoYGyFjQg2ZOHgGziRSM3VGGunwUYlPBWBwjwQcbkmsL5AlyQlITa8fMDOlXsI1aYmABun72nS0ulKLC3B16SrhCbQCUiKpAtab8YhMPUJPv1VTBbSIPVcw8FhJlUBtDv4LlElocLiEB76EAERiBH5LZIjQ8w+EV+nUogQ5E2l7s+CijHD2WhfbMjll+jRG9wAAAABJRU5ErkJggg==}
	set IMAGE(command) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAfUlEQVR4nO3UwQ7AIAgDUD99f85uHhaYxUDFBJOe+yToGMWOkKKXizyUaAhauYVowF0Aa7spAOSZpQFWJakA9IYoYhuA3i4UsLto4YCo8gY04F7AsWfonUL4R+SZAgp1AxCEd0puwBdhJRXwh0hdwug0oByAitDKJ4KUOucFYkNUm5SaVzgAAAAASUVORK5CYII=}
	set IMAGE(constructor) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAApklEQVR4nO3U0Q6AIAgFUD7dP69earkh3itgtWRj68l7Qkrkg7V1Oje0lM3sDEw3tIMZD/aEKxOZ89YR0wgPZxHsaOGrQgDwQcdT1REIapSjAAvxbwC9zR6AhoC3/WwNoLULoAWxbZ29AO8HPL6EMz9DCuEFaOELQCE8ACucRgiw7Ww4dRVso4AUBBN+ISIgt2sarqlv3UQIOBGplzOlmv/9zNC02gG7bHbyIV+3AgAAAABJRU5ErkJggg==}
	set IMAGE(destructor) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAwElEQVR4nNWVWQ7AIAhEPaJH8ub2r0vKMkNFKwl/hPdUiKVsGN3JXGhr3cwMGRfqyMTBX+DCjcw59YjbGA5nJZYKeFPNbgElIRb3Wh9pSaD1mgTU0GrK1MJvjzRm4JqA+64agIVrEtBwSaAIPCSASjC9aAFPgu2zn8DSJ1g6hDPWUJVAAKyEBBcFmMZsbVjAulq0XhNQJe4JDlfoOzZnYUQi8F8IpEgw8FNihEi55iEcU0+tSpTYFqTEa9VmQNPiAJpTEOJnKljHAAAAAElFTkSuQmCC}
	set IMAGE(method) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAeElEQVR4nO3SUQoAIQgE0I7e0bpZfW3EoouKDa4YCEFjPqLWgq0JKnp4HxNSFAI2nEMUIDbg/MGKyz/zZoBX9t8ALi/NmQHvvTXnAqB6IADuckkmD0Dy3PkBmg+ZF/CcaXtcAdaeAhRABbhRBQgHgCKo4RsBqjhrAbRnP3ykT+VmAAAAAElFTkSuQmCC}
	set IMAGE(namespace) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAWklEQVR4nO2WsQoAIAgF/fT+3KYGDVKswOEOHN/lkjwRaI66+Z2zAh1qJiGs5naRlzjZ61xOEsiqORbot8BRFkiePC7S4BsaYUFwfYgAYEEfoA+wAH2APgDfmRKyRU678ERcAAAAAElFTkSuQmCC}
	set IMAGE(namespace_old) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAA1UlEQVR4nO2XMQ6CQBBFJxbU0FqQcAlKzkBhZeUlvICF4QLewTNwAm/gBWgsPYCsf8yaEOLOboGOxWzyOmbeC9kCyDlHmqjKgwE4DTiCbsY2uhDPfJjjXU1SAE4G7sAFqAV5LczxziwlIBeWMK0Q0EZmcwtIvQM7gVIIKCOz4TuAU4FNZMESsKOaeGkFTmCMvL4lGb2T3bT/oXgOu+mqGMBueigGsFtN/sYCLMACLMACLEA/4KYoZzedFQPYTWswKMiHl9t/mRbgAHpw+TK9dxV/8Xf8BJSvNAwWvU6lAAAAAElFTkSuQmCC}
	set IMAGE(novariable) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAnUlEQVR4nOXXYQqAIAyG4d3/bN4pf1Uim5tzX1MShLTofUAIIjpwXIOJj5ZSxInAqFEDxh/3hAVITtyLCI17EKkASNyKgMYtiH8DxIdn9lcQewK4GLem7pN9X/f7EAB3rw2nAcKOQHtxewSfA6T1kQAzYvUIpLgKiJpbA+AILQ5FWONbAMIRs/FQhDf+ILwQer8NISPt12yIYeZ5owKZcPGkh9g4awAAAABJRU5ErkJggg==}
	set IMAGE(nsvar) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAADVklEQVR4nKWXS0hVQRjHRyt6KfTQyLCiRQ+opDQC20SoFa2KVi3qQolK4CKNWiSFUF3oCRU9SYi4UdkTQpMKrLBskVBghFn0hloUvUOl2//rfuP9nHvmnDm3gR/emfke/zMz5zujisfjyhW0QlAPLoN28Aq8Aw/BNbAPLAKDnWM6JB0BtnCyuCOfwGEwIW0BaBmgArw3gvfx058H+8EuEAOt4IdhS/0dYGQoAfzUjUaw+2AtGBuwWsvBRcO3A+Q7CUDLA0+EcxdYEeascJz54K6IQytZ6CsAbTjoFE73QFbY5CJeJm+RjvcBTPYTcM5Yul9gSciktaDGGCsXMR+D7BQBaBFjv3/zb/q71DH5GhEjasxtF3NHBghAGwZe82Q3LTslDSMCbQ74aaxgVMzTW9XM471gmhRQK5xWCidTRJkl+WjwwkjuJWI6J6dOoxSgT327R3Apos1y0JosyTUbhP1RlawnY2hgqjCstDxhiUoUmojHXH1AcqJO2M8T46tpYCN3/oA8h4M2ESwApaCa/WyJaeWqPGLosn6BOqe40xmQmGpEFPQ4PHGcz0SRJVYD2zylzi3uXPdJngOeOyYmroJRPvH0K/lFsQrqNASsQFXAcuvXaxPICIhVLXzUM/5xwmH/KwNElDsWrPVSQCv/aHJ0PuMjYrFjDP3mfKdOjDuPHByL+RD2WkQsdBRwnO1p9VWdShaGnICD+IZte1i4FEGipjgK6GIfusapAhEkpdCwA1W7FrYhEcU8vk6I2MNjEd7WEkus2SJfhR7UdfymxWkbz7eYq6QStyQqLFncb1M+n3ISqpKFb7yZgCg1HMp4eckm07Y9hr3nVxQtn4VRp/nfGE9kg488Qfe3IcKBbkieX0GfPfb8lKOdFk8/t1+AR3E4RiLAbmW5TKYh4qCIH+u3Ew6DwA1htFOvRLoYIjQvQW6KAHag73O3MD5Awv5TxCERj/5PKBgw7+Ewg1VqpzvK8lULSDxJJaqmTJ76Vlicc8Ft4UyH5qxK3AGs26IS974isFecdoJe81mePj7B6BBuBd+MPfwMrvD2bAY1nJAEvjVsqbqeVH4V1mEpx/EJ/moE94NK9SUwMzB+iD0dCpbxK/qAn7aPt4f+4+ngPV+lfC4jJn8BZzVGlnrCNagAAAAASUVORK5CYII=}
	set IMAGE(object) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAsUlEQVR4nO2U2QrAIAwE8+n9c/vUS1ZzmNUWGhAfAs64SkQ+WEVZXOhWSncxZFSoIhMHj8BBInNunZFGOtwrsVSABrdI0OGaRPgwuoBU084jgPpIwH3ASAJIwh3v0bvvdUIoMYpA71mmCESe6BcwCUQBqQL1D0cfTutbBFSJ6GolVMPTBVAaUwUMcrCWwukSFvgrBCgSHvgpkSEi13wI19RbNyXEmIg8pyKl4PhlQ2m1AzRIYq8CWomZAAAAAElFTkSuQmCC}
	set IMAGE(procedure) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAZklEQVR4nO3TQQoAIAgEQJ/ez+vWyUopV4NVvEU7kIkUqw4aPbyBWkPAwlcIAv4AnLY7HeBBXAFOuBSAFxECsJ4hIAyQugPQX7Abyz0hAGtw2BMQQAABEMDLJqAcAIrQwicCNHVqAIun7EQknLoRAAAAAElFTkSuQmCC}
	set IMAGE(property) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAACfElEQVR4nL2XT0jUQRTHZw0xSBEUl8oOuiRCBGLWzVKkwJN1EeyYGESCBF5EIuiSlyIKD0FECdKapQfZMIjwsNJeMkGRqBSSOgQegvyTkLl+Hzs/fLyd+f387Y4NfGB35s1739/Me29/q9LptHIJxgnwAFSzuVIwCOqz7PdBwAdAHxJsblDPrfwPAV4wYgq8Af/094l9FYARAc+ZAEkCFDgVgFELfoCXYMwnuMcoeAQWQJMLAXctgebBDc17i82wCwFl4KkheAWzKQEpYUO5EXN5/2+Z8z7D+hW2nnKehBjvAgRcZetJl0l4DLwSxzsHyplNMZgWNiPgiAsBDy0JNguuaWTwcEmok+obJY5hjVrvIhgCL/ZQhtQL4mAZnNtL8MNs8yY44GMbCRCRkPulg1bQKeZahJNaEbAXnGFzz5gtHX2SfY9niRbBN1mCUH1fNNTva9AMjqrd0vsFGrSfL3punPn22vOyn4B7ItDfgLuU633azynwGFQy31HwBDT6CTioMv05KIlMJP1ywzfHxH03hnhij23FXj7yFXDdEICOswYUgJMqu+kQF/ISQMenMj+r8gruW8otLuwmQRWIhBaA8RH8MTzVFiixbIpZrmNVGZpVkADbnS8FbFyz7PsZVoDNEfWEQsumqI/wxbACIvpIqel8F856LJvuCDu6xrZc8kA67heOKTe6lX6RpBMBN3V+cLsOV2V42nKsv/VTbhjWqA9E8xagSzFpERDEqAsBt3IM7tGVrwDeBWfAWXCbykoE+qwyr9rnwVe12zPaXeRADxjg5YdxSQioY2uHVOZPxmUnSWgpueMsOD1pUa7BchVAP0LrWsAnl8GJHfhAHNz/38WuAAAAAElFTkSuQmCC}
	set IMAGE(superclass) {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}
	set IMAGE(variable) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAnUlEQVR4nOXXYQqAIAyG4R29o3Uz+1WJbG7OfU1JENKi9wEhiGjDUToTHy3nIU4ERo0aMP64JyxAcuJeRGjcg0gFQOJWBDRuQfwbID48sj+DWBPAxbg1NZ/s+7rdhwC4e3U4DRB2BNqL6yP4HCCttwSYEbNHIMVVQNRcGgBHaHEowhpfAhCOGI2HIrzxB+GF0PttCBlpv2ZdDDP3GxeF3qBFA0WPMwAAAABJRU5ErkJggg==}
	set IMAGE(window) {iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAO9JREFUWMPtl70KwjAUhb+j9QcRUTd3dXLzfexT+EB9IZc6ibM+gYvLdWkgFIUiJo1ooHDpDZzk5OPAlZnRZEmaV+WgyX4zuzbZ16HlJeeAdN4Be2ATQXdrtjzUD1ACa6Af4+ZmSwFk3r9NG0/gMbCKKLtKB8LOq5PFuH2KDrSQA8Ciqi9VgoUVlFzZTy0JZb4DRVF8VCjP87oDk7QdCM2AmSkJBzJJo2eNUAx4TnSTyQHnwC1yDszSYOBVIzQDwPSfAz/PAH8GkmPgCKwlhR5M7sDJHyKd7RlQAhb4K4Gd09W7by5pWJXjWqv3VdPxA9NDf+q523gkAAAAAElFTkSuQmCC}
} else {
	set IMAGE(array) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAW0lEQVR4nLWTSQoAIAwDfbo/r+BBiqSdHDTQmxlilzG0oijUfhgxZRGoNBYgNneJbkgXV0IygP6LKTA6pfgHcPtgmRWkBTgjlZNwAbgHz7bRNR9IB0rNRNnnvAAwbQRXkglJKQAAAABJRU5ErkJggg==}
	set IMAGE(class) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAWUlEQVR4nGNgwA7+48AEAVhhAw5IyCCcGnEYhF8zuvMJGYJXMzZDkA3AqRmbODZDCCokFBaD1ACyw4DYWMAbE9gMwaeZpFSIywCKkzLcEHwGIXmJICA6OwMAkd3OwDCA2LEAAAAASUVORK5CYII=}
	set IMAGE(command) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAASElEQVR4nGNgoDL4TyTGrvn//waiMDZDiNaMyxB8iv5jkydoADa/E20ANk1kGUB2GFDNALK9QHEgUiUaaZoasWmGG0Ikph4AAAapzngF2PcDAAAAAElFTkSuQmCC}
	set IMAGE(constructor) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAATUlEQVR4nGNgwA7+48AEAVhhQ8N/rJiQQTg14jCIsGYgCcbEGEKRATidis8AZEOoZwBMAyFMOwMGLAwGPh1QJSnDDcFnEAOpuRILxgAAoS8ohxNKLtcAAAAASUVORK5CYII=}
	set IMAGE(destructor) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAXklEQVR4nLWSUQoAIAhDO7o3txCKsC1BS9iPuieWreFQojCsUUShIhA1ElDOzCCrMLImb/D5HQAbFUA9eELoNC+2BtwxMv8FlFbIPGL5G58cUvmUF+QGmnVmPkBAR3QOfu6cZM2INgAAAABJRU5ErkJggg==}
	set IMAGE(method) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAQ0lEQVR4nGNgoDL4TyTGrrnhwH+iMDZDiNaMyxBskuQZgO5fXAYSNACbYVjUEWcANleMGkAgHdA8NWLTDDeESEw9AAD6Doy5jsIdMgAAAABJRU5ErkJggg==}
	set IMAGE(namespace) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAARUlEQVR4nGNgoDJwAOIGKE2KHBg07E/Y//9/w///IBqqmBg5qAqHBrACGAbxiZGjngEUewEKHBgoCMTBARwYRtPBEEwHADEn0WFtZsmJAAAAAElFTkSuQmCC}
	set IMAGE(novariable) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAWUlEQVR4nGNgwA7+48AEAVjhmTNnsGJCBuHUiMMg8jTjMgTDmbicj80AvArxicMMIdY2nN4YhAagxTnOtEE1A/B6g5Dz8SYkYm2nSlKGG4LPICQvEQREZ2cAPN8GF1Von/UAAAAASUVORK5CYII=}
	set IMAGE(nsvar) {iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAABsUlEQVR4nH2SWUsCYRSG5we2E0R5UU1EEWalCUVWtBBFi2FEQRvRyowG1UXZbrZI0lUEXagjWWnNmJhjl73N+aRBLbp44Dvnfd6bj8PJ6hf3w1s8gWffOqQdG8LOtgy7PXi52QRl2a7+iD14Ed4yQzkZQNo/hc/baQa9aRd2tYGcnGLs4RyPThNUnx2ffsefUEYOuZmi8g5JMCLlG0P6xv4v5JArK3Fwz9crkN1dSFNRQ3SYUGco1RnpqMGtYNNzcp+ulsFJrnaoF0NIXw0zxEmjVijBuyezO1m0sPknJ1dyWrTiGg/1clBHtDeBNxQj4elns3/DisbqshwnuFqrFVdqoXr7dMSJBvBVxYgf97J5b8bI5mxHWuXBhQQTUqddUD3dDHG8XhOLdEasBtyLFj0nNyQ0g3vyzuN1u0lbdDKEsTrwlYX6nA+5kfNZcLIsI7hsQPLQgtSxFcJojVYsYO98yCGXOuwAonduSEsVSLpbkToy/0nyoJU55OacXPRuH4HFCsScPJL7zfg4aGHQm3aUkfPrVtmRKwoipw4EtF8LzJUiuFCO0Fo9ImfToCzb/QbQXFNJzMEKtwAAAABJRU5ErkJggg==}
	set IMAGE(object) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAATElEQVR4nGNgwA7+48AEAVhhw///WDEhg3BqxGEQfs3ozidkCFbNuPjoBuDVTIwhowYQoZiYqKRuOqBaaiRFM9wQfAYheYkgIDo7AwDYzA5PcZ662wAAAABJRU5ErkJggg==}
	set IMAGE(procedure) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAARElEQVR4nGNgoDL4TyTGrrmBSIjNEKI14zIEmyQKptgAHGrwG4CLTz8DKPYCxYFIcTSSbQAxEN0AkgzBphluCJGYegAAFQ2K7pWULrIAAAAASUVORK5CYII=}
	set IMAGE(property) {iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAABjklEQVR4nH2Sy0sCURSH57+sFrZp4yZo0TpaRA9q4SIwKDUS1IrMVHpQ4WhqpYabfOVj1FUYdF00OSM4v+65NoNT0eKDe875fnfgzJUASCbDwQhKTkUxwpAPjSmeMbQLKmg26VqHt6aOwmEflQsNnZSBbhoCOlOPLiHHFuzxRj7QhyIbXMSf0Iyc3ndYGn6OkAswtBIG2kn8CznkUkZSHlU8RzUoCQi8WzHMzjgtlhdduPGXrDm5rQcVUuGYoXltoHULgXdzHKxeaqIOu7OiNufk5o8YpOw+BWHh2TCDuqivfCXMOeZtTsb7DinjZWhcwcKzzoPTTpTjA1EHXbKoJ52sj38xF2R4iRuon0OwtxaDg4smSwsuJA8Ua04uLUhqpPkPD2m8AcHeKg9OOa36J+TWU3w5+scIqR2GbsZA4wLYXRkHa1H8ohIxcLfLQBnxAF4rugh30gaqEfxJOcxD7j7ItT05M/zk11A+4c/sFAI6U49mZsgWJHR1hFpCFVuTtxmSbob7A748WQXNJt0vh42Nfa3SnGEAAAAASUVORK5CYII=}
	set IMAGE(superclass) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAADdklEQVR4nFVTe0xTdxj97m1LW7QVWkSqQCkPEUSeMtQQWdwfFh9M4kyWLOg2t6nZFuYj8gjK3KiCOg0DMVBfIUEcmugUReaWDjBbHN1gD+IMS5bJYhQUgpEJtb979l2amXmTk99N7nfOPb/vOx8RPzqZJD7kvEiJesvlTHRQo+imAXhoBDfpgfDSz7hBdd4KOW15tFpKsk4zzXlOJmeCpJk8K1fhO3r852kH6t/arZQVNKC04Dhqt5Qrg+75YJHxyQvyJ2rt/7mUnyjJuEgnxy+bUPnaISXeOCFMBIaiBADh0D8VJavrlIftFuA6ncpPDoiQM0YiXxO5JjqNKMq47JtFUKJ0ArEGH2MqAOMUovV+WPjbuoUe32h7KPxt5HLGs4GuSjkL39NoVaELBi6waAXMGiBEYlDgNMmAmRGiFzByze6Vx4A+Guv+VM4kXKKmoRMxiAp+JjKkayiasxXbzTuxzbwD78xjWD/C+8ZibLZ8gB2zt2Kx5jrCdfAPuNOAq1RD+IZ+bdhcjFxyKyc2RcCTZ0b/itkY9CZg9EEKRoaS0Vs9Fz/YQ3E/2oLal63I09WKmqJdQDfdInxLD8sKXHjb+rrS9t4MDMen4k5OEvqrs/BXcy4Gz72Ens9T0eqMQeveZHzVZkNJRK7y4St7gU4aJp718J7C+un7l81cj9+S5+B2Tir+XrQI99LTMBSXhKGoRNxNWYC+DTYcSk+Fle4pxatbwD8fIbbR595SjBksYAsaw7th29BRaUfPgUz0HM2C90o2PO7F+GWFHRdNyxAb1K82UhwpqgBf30top7q7J+1InDkm5mqBcGmKG1iKHx1h8CyNw9cbF+LmGhuaYpcgUnsbNgPgMDz1DxxLUfPwGXVVyBkc19F966thZhd2gx9hWj8Kgz5Gy5vh6KgOxx7rEsRIdxAZPD1aHmO9av8xRyCHVjoketZMVU/ag/FG+lWfKhIZJBCmAzaY9+PgvGwk6H9HhD5AfjWpyzf2JQfpDB12RgSSrEZZw3k4PX7DhH2FNSI+eMLPQsJIfkVP/yjcHxHHtkvX1opHV0JV61/kz5f0Ly7TAkk7eV524RYvU6MDDZt2KWWrjqM03426jSXKH40Jqu2JqfPyYWeiZHhhmZ6vs53XeSf35BIdFJ3Uyw0eZozw+0+4Rke85XL2cus0R/qP/C+v4ufSv7lZJAAAAABJRU5ErkJggg==}
	set IMAGE(variable) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAABp0RVh0U29mdHdhcmUAVGsgVG9vbGtpdCB2OC42LjSkc+30AAAAWUlEQVR4nGNgwA7+48AEAVjh/wMNWDEhg3BqxGEQeZpxGYLhTFzOx2YAXoX4xGGGEGsbTm8MQgPQ4hxn2qCaAXi9Qcj5eBMSsbZTJSnDDcFnEJKXCAKiszMA8tLzPo37hLwAAAAASUVORK5CYII=}
	set IMAGE(window) {iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAAAAAADb6EKwIwAAAI1JREFUOMutk0EOwkAMA8dVoQghBNz6gL5r37bv2ju8gHM4ECRKUcVm8S2W7FhWIigsMV2AYcmX2ycjNzBiUOcbA9qnpqMRzQYCRuBqVleDJICtlziZmZFz/kmcUnoZHGcG9QmKBOyBezBBPzMIdHDu38maBI5TcwetCfhfAi8lcoll7WF2wMGHzbd3fgDWLTbBU0gyBwAAAABJRU5ErkJggg==}
}

if 0 {
variable images [image names]
foreach tag [glob [file join [file dirname [info script]] icons [expr {$GUI(high)?{big}:{small}}] *.png]] {
	set value ::classview::img::[file rootname [file tail $tag]]
	if {$value in $images} {image delete $value}
	image create photo $value -file $tag
}
}
foreach {name data} [array get IMAGE] {image create photo ::classview::img::$name -data [::base64::decode $data]}
array unset IMAGE
unset name data tag value toolbar

# Procedures.

proc switch_pane {{mode {}}} {
	variable GUI
	upvar [$GUI(chktext) cget -variable] show
	if {[string is boolean -strict $mode]} {set show $mode}
	if {($show^$GUI(bottom) in [$GUI(pane) panes])} {$GUI(pane) [lindex {forget add} $show] $GUI(bottom)}
}

proc traverse {root {id {}} {type {}} {idx end}} {
	variable GUI
	if {$id eq {}} {
		if {[$GUI(tree) exists $root]} {$GUI(tree) delete $root}
		lappend options -id $root -open yes
	}
	if {$type eq {}} {set type [expr {[info object isa object $root]?[expr {[info object isa class $root]?{class}:{object}}]:{namespace}}]}
	lappend options -text $root -tags $type -values <$type>
	if {$root ne [$GUI(tree) item $id -text]} {set id [$GUI(tree) insert $id $idx {*}$options]}
	foreach verb {see focus selection\ set} {$GUI(tree) {*}$verb $id}
	# Enumerate class/objects/child namespaces.
	set command [expr {$type eq {namespace}?"namespace children $root":"info object namespace $root"}]
	foreach ns [lsort [{*}$command]] {
		$GUI(tree) insert [$GUI(tree) insert $id 0 -text $ns -tags namespace] 0 -text dummy
	}
	if {$type ne {namespace}} {;# Class or Object.
# TODO: Add method types (method/forward).
# TODO: Add class methods/variables?
# TODO: unsort unnecessary entities.
		foreach entity {mixin variable method filter} {
			set command "info $type ${entity}s $root"
			if {$entity eq {method}} {append command \ -private}
			foreach instance [lsort [{*}$command]] {
				set item [$GUI(tree) insert $id $idx -text $instance -tags $entity -values <$entity>]
				if {$entity eq {mixin}} {$GUI(tree) insert $item 0 -text dummy}
			}
		}
	}
# TODO: order = namespace/(superclasses/baseclass)/variables/((con|de)structor)/methods/(instances)
	if {$type eq {class}} {
		foreach prefix {de con} {;# Add class constructor/destructor.
			$GUI(tree) insert $id 1 -text [string totitle $prefix]structor -tags ${prefix}structor
		}
		foreach collection {superclasses subclasses instances} {
			if {![regexp {\w+class} $collection value]} {set value object}
			set items [info $type $collection $root]
			foreach item [expr {$collection eq {superclasses}?$items:[lsort $items]}] {
				$GUI(tree) insert [$GUI(tree) insert $id end -text $item\
					-tags [expr {$value eq {object}?$value:{class}}] -values <$value>] 0 -text dummy
			}
		}
	}
	if {$type ne {class}} {;# Object or Namespace.
		# Enumerate variables.
		set command [expr {$type eq {object}?"info $type vars $root":"info vars ${root}::*"}]
		foreach var [lsort [{*}$command]] {
			if {$type eq {object}} {set fqvn [info object namespace $root]::$var} else {set fqvn $var}
			set value [expr {[array exists $fqvn]?[array get $fqvn]:[expr {[info exists $fqvn]?[set $fqvn]:{<undefined>}}]}]
			set tag   [expr {[array exists $fqvn]?{array}:[expr {[info exists $fqvn]?{variable}:{novariable}}]}]
			regsub -all {[[:space:]]} $value { } value
			if {[string length $value] > 200} {set value [string range $value 0 199]}
			$GUI(tree) insert $id $idx -text $var -values [list $value] -tags $tag
		}
		# Get object's baseclass and enumerate namespace procedures/commands.
		if {$type eq {object}} {
			$GUI(tree) insert [$GUI(tree) insert $id 1 -text [info object class $root]\
				-values [list "<The $type's baseclass>"] -tags class] 0 -text dummy
		} else {;# Namespace.
			foreach cmd [lsort [info commands ${root}::*]] {
				if {![catch {info args $cmd} values]} {
					set tags procedure
				} elseif {[string match "::.*" $cmd] && [winfo exists [string range $cmd 2 end]]} {
					set win [string range $cmd 2 end]
					set values "[winfo class $win] window"
					set cmd $win
					set tags window
				} else {
					set values <command>
					set tags command
				}
				$GUI(tree) insert $id $idx -text $cmd -values [list $values] -tags $tags
			}
		}
	}
}

proc tree_keypress {tree keysym} {
	set current [$tree focus]
	array set item_opts [$tree item $current]
	switch $keysym {
		Return -
		Right {
			set child [$tree children $current]
			if {[llength $child] == 1 && [$tree item $child -text] eq {dummy}} {
				$tree delete $child
				traverse $item_opts(-text) $current
			}
		}
		Delete {if {[$tree parent $current] eq {}} {$tree delete $current}}
	}
}

proc text_eval {text} {
	set source [string trim [$text get 1.0 end]]
	if {[catch {uplevel \#0 $source} error]} {
	    error $error
	}
}

proc change_selection {} {
	variable GUI
	variable show_text
	set current [$GUI(tree) focus]
	if {$current eq {} || !$show_text} return
	$GUI(text) delete 1.0 end
	array set item_opts [$GUI(tree) item $current]
	array set prnt_opts [$GUI(tree) item [$GUI(tree) parent $current]]
# foreach prefix {item prnt} {parray ${prefix}_opts}
	lassign [list $prnt_opts(-text) $prnt_opts(-tags) $item_opts(-text) $item_opts(-tags)] p_name p_type i_name i_type
	try {
		switch $i_type {
			array       {set text [array_format [expr {$p_type eq {object}?"[info object namespace $p_name]::":{}}]$i_name]}
			constructor -
			destructor  {set text [get_source $i_type $p_name]}
			method      {set text [get_source $i_type $i_name $p_type $p_name]}
			procedure   {set text [get_source $i_type $i_name]}
			command -
			namespace -
			object -
			class -
			novariable  {set text ""}
			variable    {set text "set [list $i_name] [list [set $i_name]]"}
			window      {set text [get_win_source $i_type $i_name]}
			default     {set text $item_opts(-values)}
		}
	} on error msg {set text Error:\ $msg}
	$GUI(text) insert 1.0 $text
}

proc get_proc_signature entity_name {
	set list {}
	foreach arg [info args $entity_name] {
		if {[info default $entity_name $arg def]} {
			set arg [list $arg $def]
		}
		lappend list $arg
	}
	return $list
}

proc get_source {entity entity_name {object {class}} {object_name {}}} {
	if {$object eq {namespace}} {set object class}
	switch $entity {
		constructor -
		destructor   {set definition [list oo::define $entity_name $entity]}
		method       {set definition [list oo::define $object_name $entity]}
		procedure    {set definition proc}
		default      {set definition $entity}
	}
	switch $entity {
		constructor {lassign [info class $entity $entity_name] args body}
		destructor  {set body [info class $entity $entity_name]}
		procedure   {lassign [list proc [get_proc_signature $entity_name] [info body $entity_name]] entity args body}
		method      {lassign [info $object definition $object_name $entity_name] args body}
		default     {set entity Error:\ }
	}
	if {[info exists args]} {
		if {$entity ne {constructor}} {append definition \ $entity_name}
		append definition \ [list $args $body]
	} elseif {$entity eq {destructor}} {
		append definition \ [list $body]
	} else {
		append definition "unknown entity '$entity' specified"
	}
	return $definition
}

proc array_format arr {
	upvar 1 $arr loc_arr
	if {![array exists loc_arr]} {error "'$arr' isn't an array"}
	set maxl 0
	set names [lsort [array names loc_arr]]
	foreach name $names {if {[string length $name] > $maxl} {set maxl [string length $name]}}
	incr maxl [expr {[string length $arr]+2}]
	set chunk {}
	foreach name $names {lappend chunk [format "set %-*s %s" $maxl [format %s(%s) $arr $name] [list $loc_arr($name)]]}
	return [join $chunk \n]
}

proc get_win_source {entity entity_name} {
	set win $entity_name ;# [string range $entity_name 2 end]
	set chunk ""
	if {[winfo exists $win]} {
		catch {
			set cls [winfo class [list $win]]
			if {$win eq "."} {
				set cmd "::toplevel"
			} elseif {[string match {T[A-Z]*} $cls]} {
				set cls2 [string range $cls 1 end]
				set cmd [info command "::ttk::[string tolower $cls2]"]
			} else {
				set cmd [info command "::[string tolower $cls]"]
				if {$cmd eq ""} {
					set cmd [info command "::ttk::[string tolower $cls]"]
				}
			}
			if {$cmd ne ""} {
				append chunk "# [list $cmd] [list $win]\n"
			}
			set ismenu [expr {$cmd eq "::menu"}]
		}
		catch {
			foreach cfg [$win configure] {
				if {([llength $cfg] == 5) && ([lindex $cfg 3] ne [lindex $cfg 4])} {
					lappend opts [lindex $cfg 0] [lindex $cfg 4]
				}
			}
			if {[llength $opts]} {
				append chunk "[list $win] configure"
				foreach {name val} $opts {
					append chunk " \\\n    [list $name] [list $val]"
				}
			}
			append chunk "\n"
		}
		catch {
			set wman [winfo manager [list $win]]
			if {($wman eq "place") || ($wman eq "pack") || ($wman eq "grid")} {
				set opts [[list $wman] info [list $win]]
				if {[llength $opts]} {
					append chunk "[list $wman] configure [list $win]"
					foreach {name val} $opts {
						append chunk " \\\n    [list $name] [list $val]"
					}
					append chunk "\n"
				}
			}
		}
		catch {
			# panedwindow geometry manager
			foreach child [$win panes] {
				if {[catch {$win paneconfigure $child} opts]} {
					if {[catch {$win pane $child} opts]} {
						set opts {}
					} else {
						set pcmd "pane"
					}
				} else {
					set pcmd "paneconfigure"
				}
				if {[llength $opts]} {
					append chunk "[list $win] $pcmd [list $child]"
					foreach {name val} $opts {
						append chunk " \\\n    [list $name] [list $val]"
					}
					append chunk "\n"
				}
			}
		}
		catch {
			# notebook geometry manager
			foreach child [$win tabs] {
				set opts [$win tab $child]
				if {[llength $opts]} {
					append chunk "[list $win] tab [list $child]"
					foreach {name val} $opts {
						append chunk " \\\n    [list $name] [list $val]"
					}
					append chunk "\n"
				}
			}
		}
		catch {
			set top [winfo toplevel $win]
			if {$top eq $win} {
				set bt [list $win [winfo class $win] all]
			} else {
				set bt [list $win [winfo class $win] $top all]
			}
			if {[bindtags $win] ne $bt} {
				append chunk "bindtags [list $win] [list [bindtags $win]]\n"
			}
		}
		catch {
			foreach b [bind $win] {
				append chunk "bind [list $win] [list $b] [list [bind [list $win] $b]]\n"
				incr n
			}
		}
		catch {
			if {$ismenu} {
				set end [$win index end]
				append chunk "[list $win] delete 0 end\n"
				for {set i 0} {$i < $end} {incr i} {
					append chunk "[list $win] add [$win type $i]"
					set opts {}
					foreach cfg [$win entryconfigure $i] {
						if {([llength $cfg] == 5) && ([lindex $cfg 3] ne [lindex $cfg 4])} {
							lappend opts [lindex $cfg 0] [lindex $cfg 4]
						}
					}
					foreach {name val} $opts {
						append chunk " \\\n    [list $name] [list $val]"
					}
					append chunk "\n"
				}
			}
		}
	}
	return $chunk
}

# Toolbar procedures

proc tbb.show {} {
	variable entity
	if {$entity ne {}} {
		traverse $entity
	} else {
		puts stderr {Error: please enter some entity}
	}
}

proc tbb.demo {} {
	puts "Demo: showing namespace - [namespace current]"
	traverse [namespace current]
	puts "Demo: showing class - ::oo::class"
	traverse ::oo::class
	puts "Demo: showing class as object - ::oo::object"
	traverse ::oo::object {} object
}

proc tbb.clear {} {
	variable GUI
	$GUI(tree) delete [$GUI(tree) children {}]
	$GUI(text) delete 1.0 end
}

recursive_bind $GUI(win) $GUI(win) yes
# wm geometry $GUI(win) 1350x850
switch_pane
if {{console} in [info commands]} {console show}

}

package provide classview 0.1


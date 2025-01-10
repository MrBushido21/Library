namespace eval gid_themes {
}

#common
proc gid_themes::ImageCreatePhoto { filename} {
    package require Img
    set extra_opts ""
    if { [ string tolower [ file extension $filename ] ] == ".png" } {
        set extra_opts [ list -format "png -gamma $::gamma_value" ]
    }
    set img [ image create photo -file $filename -gamma $::gamma_value {*}$extra_opts ]
    return $img
}

proc gid_themes::GetImageNoImage {} {
    # themes/GiD_classic/images/small_size(16andmore)/erase-cross.png
    set return_img [ image create photo erase-cross-16x16.png -data {
            iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAB3RJTUUH2woaDBkBJCSJ/AAAAAlw
            SFlzAAAewQAAHsEBw2lUUwAAAARnQU1BAACxjwv8YQUAAALNSURBVHjapVJLaFNBFD3vzfskjaZJ
            TNOkxvijfhIVNV0UvygVvytxpwtFXAgKimKlIiKC4kJEECld6UJEUHTlp+KiLly1UFxIVdpo1ZCa
            NDF9L3n/GV9q46eoGwdmGIZzzz33nAH+c3Gs8/QNtDTvZxy8rDjxgY7mDgjZzEvuyRNjOvj93r0x
            ygsdYii8lfk9m/SqpgtIRA5hdoPAVapAIDiXm+m9axBc70+nL7UNDFi1QpZOix9bU3ukxuBh37xE
            u9ggiLRSKpYc446AsewoPP4F0E1wmglCxCYk4+dTPJcsxmKnLOINFYOBC03z5+2SiQjn3VtNnfja
            O5wrnWzr6x0S8LlwDLx5GX55EWyLQFFBaBloCexxTCshNfgiciyykLz/BHt8vFI0tTOayt1yi79O
            ejApcd22JiyedQp+aR+8JArDBiru9oUAnQJDb1Gt6BlFkk9EXzx78JuJ9QtLJiUsXdjqKOUrhGpb
            UFJ5aDUiCxWlgryq77hpKk/PA/SfsajhcLe9faPJliYYmxNlLBxhlj/Ahol8ux8IT8fzPxQAsub1
            HfWuXXaQ10siDAOuBzalNhNcoRFB3O0FOfJXAlvy7pTWrT7L22WBy+dBbQfVCfW2qVQfUodiBsd7
            wrzQ9RhY/SsBmeo+h1+z8hEXEcP4nHXZKMwv6ktV1Y9XqH1PslkLT8gKn3toDl2wAfT5fUCZVOAW
            B7Gk9SpS0RC+5FxbOVDXuGrZ7GoGhmcDhdfM7FRNow+MIS4K6+Pgt/4cQW5Mo33RZnwaQQ0Ay6HG
            hNETgt1XB6WB7Ahjx0qWPhiQRI+fcCfOTY3PozkUxHguWA/VUY0RWta7p5u1CtZgFqzToBRxWUzF
            gcXfCXKFVyiU+2GxWuZlJ1O+6LOswT9FvBxO75hp9vhlQgVgR+1N4EzlDctIhxGQOpCvDsmW9fBf
            /2TMsa75LGFtPcFvO84/23ouD+IAAAAASUVORK5CYII=
        } ]
    return $return_img
}
#end common

proc gid_themes::SetFontsDefault { disp_height } { } 
proc gid_themes::SetOptions { } { }
proc gid_themes::ReadThemes { } { }
proc gid_themes::SetNextRestartTheme { name } { }
proc gid_themes::GetNextRestartTheme { } { }
proc gid_themes::SetCurrentTheme { name } { }
proc gid_themes::GetCurrentTheme { } { }
proc gid_themes::GetDefaultTheme { } { }
proc gid_themes::SetCurrentThemeColors { name } { }
proc gid_themes::CheckThemes {} { }
proc gid_themes::LoadImage { filename {IconCategory "generic"} } {
    set fullname $filename
    if { [ info exists ::GidPriv(no_gid_theme,$IconCategory) ]} {
        set fullname [ file join $::GidPriv(no_gid_theme,$IconCategory) $filename ]
    }
    return [ gid_themes::ImageCreatePhoto $fullname ]
}
proc gid_themes::GetImage { filename {IconCategory "generic"} } {
    if { [ info exists ::GidPrivImages($IconCategory,$filename) ] } {
        set img $::GidPrivImages($IconCategory,$filename)
    } else {
        set err_img [ catch {set img [ gid_themes::LoadImage $filename $IconCategory ] } err_txt ]
        if { $err_img } {
            set img [ gid_themes::GetImageNoImage ]
        } else {
            set ::GidPrivImages($IconCategory,$filename) $img
        }
    }
    return $img
}  
proc gid_themes::GetOnlyDefineColorsOnMainGiDFrame { } { }
proc gid_themes::GetTtkTheme { } { }  
proc gid_themes::GetTkFromTheme { } { }
proc gid_themes::GetTypeMenu { } { }
proc gid_themes::GetPaddingWidgets { } { }


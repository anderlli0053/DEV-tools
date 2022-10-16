# Written by Andrew Poženel AKA SloDevTeam, 2011-2022


import os, sys, json, json_minify, shutil, glob


MoveFROMPath = (r"C:\Users\ander\Desktop\DEV-tools\bucket\\")

MoveTOPath = (r"C:\Users\ander\Desktop\DEV-tools\working_but_removed_upon_request\\")



manifests_to_remove = [

"bandicam-zd423.json",
"bandizip-portable.json",
"bandizip-zd423.json",
"beyondcompare-chs-np.json",
"beyondcompare-djcl.json",
"beyondcompare-zd423.json",
"bitcomet-gh.json",
"bongocat-mver.json",
"btbtt-url-tool.json",
"cajviewer-lite-portable.json",
"careueyes-chs.json",
"careueyes-elchupacabra.json",
"careueyes-elchupacabra-portable.json",
"careueyes.json",
"ccleaner-gh.json",
"cheat-engine-chs.json",
"chrome-beta-shuax.json",
"chrome-canary-shuax.json",
"chrome-dev-shuax.json",
"chrome-flash-wenlei.json",
"chrome-plus.json",
"chrome-stable-shuax.json",
"clashdotnetframework.json",
"clashdotnetframework-modified.json",
"clashdotnetframework-mod.json",
"cloudmusic.json",
"cloudmusic-unblock.json",
"cloudmusic-zd423.json",
"copybookbuilder.json",
"directx_repair.json",
"dnshelper.json",
"dns-youxuan.json",
"drivertalent-zd423.json",
"edrawmax-zd423.json",
"faststone-capture.json",
"faststone-image-viewer.json",
"fiddler-everywhere-crack-3.2.1.json",
"fiddler-everywhere-crack-3.3.0.json",
"finalshell.json",
"firefox-tete009-portable.json",
"fsviewer-gh.json",
"gifcam-chs.json",
"gif-movie-gear.json",
"gjgjx.json",
"haoziprename-wenlei.json",
"hrsword.json",
"idm-elchupacabra.json",
"idm-elchupacabra-portable.json",
"internet-download-manager.json",
"internet-download-manager-portable.json",
"iobit-uninstaller-portable-gh.json",
"iobit-uninstaller-pro.json",
"iobit-uninstaller-qiuquan.json",
"iobit-unlocker-gh.json",
"iris-gh.json",
"ja-netfilter-all.json",
"jixia.json",
"kuwo-zd423.json",
"licecap-chs.json",
"ludashi-zd423.json",
"mas-chs.json",
"microsoftkeys.json",
"msedge-beta-shuax.json",
"msedge-canary-shuax.json",
"msedge-dev-shuax.json",
"msedge-plus.json",
"msedge-stable-shuax.json",
"musictag.json",
"opera-portable-gh.json",
"oraclejdk-11.0.13-portable.json",
"oraclejdk-11.0.14-portable.json",
"oraclejdk-11.0.15.1-portable.json",
"oraclejdk-11.0.15-portable.json",
"oraclejdk-11.0.16-portable.json",
"oraclejdk-8u311.json",
"oraclejdk-8u311-portable.json",
"oraclejdk-8u321.json",
"oraclejdk-8u321-portable.json",
"oraclejdk-8u331.json",
"oraclejdk-8u331-portable.json",
"oraclejdk-8u333.json",
"oraclejdk-8u333-portable.json",
"oraclejdk-8u341.json",
"oraclejdk-8u341-portable.json",
"pdf-xchange-editor-zd423.json",
"potplayer-2017109-wenlei.json",
"potplayer-20190822-dio.json",
"potplayer64-20171027-dio.json",
"potplayer64-20190828-wenlei.json",
"potplayer64-dev-noad-portable.json",
"potplayer64-noad-portable-7sh3.json",
"potplayer64-noad-portable.json",
"potplayer-dev-191121-wenlei.json",
"potplayer-dev-noad-portable.json",
"potplayer-noad-portable.json",
"potplayer-skins.json",
"processmonitor-chs.json",
"qq-dreamcast.json",
"qq-dreamcast-portable.json",
"qq-mod.json",
"qq-mod-portable.json",
"qqmusic-zd423.json",
"qq-ntr-dreamcast.json",
"qq-ntr-dreamcast-portable.json",
"qq-ntr-mod.json",
"qq-ntr-mod-portable.json",
"qqscreenshot.json",
"qq-xueyu-portable.json",
"qq-zd423-portable.json",
"revo-uninstaller-pro.json",
"revo-uninstaller-qiuquan.json",
"rmtool.json",
"runningcheese-chrome.json",
"runningcheese-edge.json",
"runningcheese-firefox.json",
"screencapture.json",
"shumaxiaozhan.json",
"sogouinput10-portable-zd423.json",
"sogouinput10-xingkbjm.json",
"sogouinput10-zd423.json",
"sogouinput11-portable-zd423.json",
"sogouinput11-xingkbjm.json",
"sogouinput11-zd423.json",
"sogouinput12-portable-zd423.json",
"sogouinput12-xingkbjm.json",
"sogouinput12-zd423.json",
"sogouinput6-dashuiniu.json",
"sogouinput9-xingkbjm.json",
"sogouinput9-zd423.json",
"sogouinput-xingkbjm.json",
"sogouinput-zd423.json",
"sogouwbinput3-qiuquan.json",
"sogouwbinput3-xingkbjm.json",
"sogouwbinput4-qiuquan.json",
"sogouwbinput4-xingkbjm.json",
"sogouwbinput5-qiuquan.json",
"sogouwbinput5-xingkbjm.json",
"sogouwbinput-qiuquan.json",
"sogouwbinput-xingkbjm.json",
"tbtool.json",
"text-counter-appinn.json",
"thunder11-zd423.json",
"thunderx-zd423.json",
"tim-mod-portable.json",
"tim-zd423.json",
"totalcommander-chs.json",
"totalcommander-iyoung.json",
"totalcommander-license.json",
"tts-dangtone.json",
"typa.json",
"typeeasy.json",
"typeeasy-qiuquan.json",
"typora-beta.json",
"typora-crack.json",
"uninstall-tool.json",
"uninstall-tool-portable-gh.json",
"uninstall-tool-portable.json",
"uninstall-tool-qiuquan.json",
"url-encode-decode-tool.json",
"vcredist-dreamcast.json",
"wechatdownload.json",
"wechat-qiuquan.json",
"wechat-revoke-zd423.json",
"wechat-zd423.json",
"wenxun-ping.json",
"windows10manager-gh.json",
"windows-update-minitool.json",
"wintool.json",
"wise-care-365.json",
"wise-care-365-portable-gh.json",
"wise-care-365-portable.json",
"wise-care-365-portable-qiuquan.json",
"wise-care-365-pro-portable.json",
"wise-care-365-qiuquan.json",
"wise-registry-cleaner-gh.json",
"wise-registry-cleaner-qiuquan.json",
"wps2019pro-c2y-cef.json",
"wps2019pro-c2y-nocef.json",
"wxdatviewer.json",
"x64dbg-gh.json",
"xftp-portable.json",
"xshellplus-portable.json",
"xshell-portable.json",
"xyplorer-pro-crack.json",
"xyplorer-pro-zd423.json",
"yoco.json",
"yyspeak-zd423.json"

    ]



for file in manifests_to_remove:
    
    # constructing full file path
    source = MoveFROMPath + file
    destination = MoveTOPath + file

    # moving....
    
    shutil.move(source, destination)
    print("Moved: " , file)











##
##    for files in manifests_to_remove:
##        if files.name.endswith(".json"):
##            print("Moving" + files.name + " -> " + files.path)
##




##    for files in os.scandir(MoveTOPath):
##        if files.name.endswith(".json"):
##            print(" -> " + files.path)
##
##
##
##    pass

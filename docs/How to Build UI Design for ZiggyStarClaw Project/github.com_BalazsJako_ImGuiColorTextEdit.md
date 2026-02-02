# GitHub - BalazsJako/ImGuiColorTextEdit: Colorizing text editor for ImGui

**URL:** https://github.com/BalazsJako/ImGuiColorTextEdit

---

Skip to content
Navigation Menu
Platform
Solutions
Resources
Open Source
Enterprise
Pricing
Sign in
Sign up
BalazsJako
/
ImGuiColorTextEdit
Public
Notifications
Fork 310
 Star 1.7k
Code
Issues
36
Pull requests
22
Actions
Projects
Wiki
Security
Insights
BalazsJako/ImGuiColorTextEdit
 master
2 Branches
0 Tags
Code
Folders and files
Name	Last commit message	Last commit date

Latest commit
BalazsJako
Merge pull request #166 from ocornut/fix_for_192
ca2f9f1
 · 
History
185 Commits


.gitignore
	
Update .gitignore
	


CONTRIBUTING
	
Create CONTRIBUTING
	


LICENSE
	
Initial commit
	


README.md
	
Update README.md
	


TextEditor.cpp
	
Update to work on latest Dear ImGui: removed obsolete calls to GetKey…
	


TextEditor.h
	
Removed static local variables.
	
Repository files navigation
README
Contributing
MIT license
ImGuiColorTextEdit

Syntax highlighting text editor for ImGui

Demo project: https://github.com/BalazsJako/ColorTextEditorDemo

This started as my attempt to write a relatively simple widget which provides text editing functionality with syntax highlighting. Now there are other contributors who provide valuable additions.

While it relies on Omar Cornut's https://github.com/ocornut/imgui, it does not follow the "pure" one widget - one function approach. Since the editor has to maintain a relatively complex and large internal state, it did not seem to be practical to try and enforce fully immediate mode. It stores its internal state in an object instance which is reused across frames.

The code is (still) work in progress, please report if you find any issues.

Main features
approximates typical code editor look and feel (essential mouse/keyboard commands work - I mean, the commands I normally use :))
undo/redo
UTF-8 support
works with both fixed and variable-width fonts
extensible syntax highlighting for multiple languages
identifier declarations: a small piece of description can be associated with an identifier. The editor displays it in a tooltip when the mouse cursor is hovered over the identifier
error markers: the user can specify a list of error messages together the line of occurence, the editor will highligh the lines with red backround and display error message in a tooltip when the mouse cursor is hovered over the line
large files: there is no explicit limit set on file size or number of lines (below 2GB, performance is not affected when large files are loaded (except syntax coloring, see below)
color palette support: you can switch between different color palettes, or even define your own
whitespace indicators (TAB, space)
Known issues
syntax highligthing of most languages - except C/C++ - is based on std::regex, which is diasppointingly slow. Because of that, the highlighting process is amortized between multiple frames. C/C++ has a hand-written tokenizer which is much faster.

Please post your screenshots if you find this little piece of software useful. :)

Contribute

If you want to contribute, please refer to CONTRIBUTE file.

About

Colorizing text editor for ImGui

Topics
c syntax-highlighting sql lua cplusplus utf-8 imgui glsl color-palette undo-redo text-editor sourcecode hlsl utf8 autoindent
Resources
 Readme
License
 MIT license
Contributing
 Contributing
 Activity
Stars
 1.7k stars
Watchers
 46 watching
Forks
 310 forks
Report repository


Releases
No releases published


Packages
No packages published



Contributors
9


Languages
C++
100.0%
Footer
© 2026 GitHub, Inc.
Footer navigation
Terms
Privacy
Security
Status
Community
Docs
Contact
Manage cookies
Do not share my personal information
EXZLER by Zachary Recolan

Compiler in Swift
============================================

This is the project for CMPT 432N-111 Compilers. Final submissions are pushed to master

BUILD:
swift build -c release --build-path Distrib -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13

RUN:
[flags]
-f FILENAME : specifies filename. Filename must follow -f flag
-v : specifies verbose mode
-l : specifies test lexing

[example]
Distrib/release/EXZLER -f FILENAME -v
(read source from file FILENAME, and verbosely print results)

[testing]
Test cases are partially automated and documented in 'tester.swift'. Run with...
Distrib/release/EXZLER -l
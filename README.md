EXZLER by Zachary Recolan

Compiler in Swift
============================================

This is the project for CMPT 432N-111 Compilers. Final submissions are pushed to master

BUILD:
```
swift build -c release --build-path Distrib -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13
```

RUN:

[flags]
```
-f FILENAME : specifies filename. Filename must follow -f flag
-v : specifies verbose mode
-t : specifies test EXZLER
```

[example] (read source from file FILENAME, and verbosely print results)
```
Distrib/release/EXZLER -f FILENAME -v
```

[testing] Test cases are partially automated and documented in 'Tester.swift'. Run with...
```
Distrib/release/EXZLER -t
```

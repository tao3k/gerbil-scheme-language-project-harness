((package "sample/app" "gerbil.pkg" "gxpkg" ("git.cons.io/mighty-gerbils/gerbil-poo"))
 (extensions
  (("poo"
    "gerbil.pkg"
    "required"
    "gxpkg"
    "sample/app"
    ("git.cons.io/mighty-gerbils/gerbil-poo")
    ("object-system" "metaobject-protocol" "protocols"))))
 (search-lines
  ("|extension name=poo activation=gerbil.pkg packageManager=gxpkg dependencyMode=required package=sample/app dependencies=git.cons.io/mighty-gerbils/gerbil-poo capabilities=object-system,metaobject-protocol,protocols")))

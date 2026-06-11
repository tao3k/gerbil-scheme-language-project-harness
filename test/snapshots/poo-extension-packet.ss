(extensionPacket
 (projectPackage
  (path "gerbil.pkg")
  (name "sample/app")
  (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
  (fields (packageManager "gxpkg")))
 (extensions
  ((providerExtension
    (name "poo")
    (activation "gerbil.pkg")
    (dependencyMode "required")
    (packageManager "gxpkg")
    (package "sample/app")
    (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
    (capabilities ("object-system" "metaobject-protocol" "protocols")))))
 (searchLines
  ("|extension name=poo activation=gerbil.pkg packageManager=gxpkg dependencyMode=required package=sample/app dependencies=git.cons.io/mighty-gerbils/gerbil-poo capabilities=object-system,metaobject-protocol,protocols")))

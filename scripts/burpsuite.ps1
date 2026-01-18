$exe=_EXE_
$ldr=_LDR_

java -noverify `
    --add-opens=java.desktop/javax.swing=ALL-UNNAMED `
    --add-opens=java.base/java.lang=ALL-UNNAMED `
    --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED `
    --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED `
    --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED `
    -javaagent:$ldr `
    -jar $exe

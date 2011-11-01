ExpressionAST subclass: #ASTChoiceOp
              instanceVariableNames: 'condition choices'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTChoiceOp comment: 
    'I model a mux, can be 2^n choices, n from 1 to many'!

!ASTChoiceOp class methodsFor: 'instance creation'!

newChoice: c among: cs
    ^super new
        condition: c;
        choices: cs!
!

!ASTChoiceOp methodsFor: 'accessing'!

clearAlias
    super clearAlias.
    condition clearAlias.
    choices do: [ :each | each clearAlias ]!

width
    ^choices inject: 0 into: [ :m :c | m max: c width ]!

condition
    ^condition!

condition: c
    condition := c!

choices
    ^choices!

choices: cs
    choices := cs!

dependencies
    ^choices inject: condition dependencies into: [ :list :each |
        list, each dependencies ]!
!

!ASTChoiceOp methodsFor: 'basic'!

checkDesign
    |result w|
    result := choices size == (1 bitShift: condition width).
    result := result & condition checkDesign.
    w := self width.
    ^choices inject: result into: [ :r :each |
        |ew|
        ew := each width.
        r & each checkDesign & ((ew == 0) | (ew == w)) ]!

context: c type: t
    condition context: c type: t.
    choices do: [ :each | each context: c type: t ]!

destroy
    condition destroy.
    choices do: [ :each | each destroy ]!

evaluate
    |v|
    v := condition evaluate.
    ^ (choices at: (choices size - v)) evaluate!

staticValue
    |v|
    v := condition staticValue.
    v notNil ifTrue: [ 
    ^ (choices at: (choices size - v)) staticValue ].
    ^nil!

optimize
    |v result r|
    condition := condition optimize.
    choices := choices collect: [ :each | each optimize ].
    v := condition staticValue.
    v notNil ifTrue: [ 
        1 to: choices size do: [ :i |
            r := choices at: i.
            i == (choices size - v) 
                ifTrue: [
                    r width == 0 ifTrue: [ r width: self width ].
                    result := r ]
                ifFalse: [ r destroy ]].
        result notNil ifTrue: [ ^result ]]!
!

!ASTChoiceOp methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
"a?b:c can be inlined. However, the extension a[1:0]?b:c:d:e must be treat
differently"
    condition printAdditionalVerilogOn: aStream.
    choices do: [ :c |
        c printAdditionalVerilogOn: aStream ].
    choices size > 2 ifTrue: [
        self printVerilogOn: aStream withAlias: 'Choice' ]!

printVerilogOn: aStream
    |deps|
    choices size > 2 
        ifFalse: [ ^super printVerilogOn: aStream ]
        ifTrue: [ self printVerilogRegsOn: aStream ].
    deps := self dependencies.
    DANMExpressionWire printDependencies: deps uniquify on: aStream.
    self printCoreVerilogOn: aStream indent: 8 blocking: true!

printCoreVerilogOn: aStream indent: num blocking: blocking wrapping: wrapping
    |s w e|
    s := choices size.
    s > 2 ifFalse: [ 
        ^super printCoreVerilogOn: aStream indent: num 
               blocking: blocking wrapping: wrapping ].
    w := condition width.
    aStream 
        next: num put: $ ;
        nextPutAll: 'case (%1)' 
            % {condition printStringStyle: #VERILOG}; nl.
    0 to: s - 1 do: [ :i |
        aStream 
            next: num + 4 put: $ ;
            nextPutAll: '%1d%2: ' % {w. i}; nl.
        e := choices at: s - i.
        e alias: alias.
        e printCoreVerilogOn: aStream indent: num+8 
          blocking: blocking wrapping: false ].
    aStream
        next: num put: $ ;
        nextPutAll: 'endcase'; nl!

basicPrintStringStyle: style
    |aStream|
    aStream := WriteStream on: String new.
    aStream nextPutAll: ('(%1?' % {condition printStringStyle: style}).
    1 to: choices size do: [ :i |
        i == 1 
            ifTrue: [aStream nextPutAll: ('%1' % 
                         {(choices at: i) printStringStyle: style})]
            ifFalse: [aStream nextPutAll: (':%1' % 
                         {(choices at: i) printStringStyle: style}) ]].
    aStream nextPut: $).
    ^aStream contents!
!

ExpressionAST subclass: #ASTIfsOp
              instanceVariableNames: 'conditions choices'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTIfsOp comment: 
    'I model a priority encoded mux, like 
    if () 
        a=b; 
    else () 
        a=c; 
    else 
        a=d;
I cannot be sub expression to some other expression though. '!

!ASTIfsOp class methodsFor: 'instance creation'!

newIfs: ifs
    |conditions choices|
    conditions := OrderedCollection new.
    choices := OrderedCollection new.
    ifs do: [ :each |
        |c v|
        c := ExpressionAST newFrom: each key.
        v := ExpressionAST newFrom: each value.
        conditions add: c.
        choices add: v].
    ^self newConditions: conditions choices: choices!
    
newConditions: cs choices: vs
    cs size == vs size ifFalse: [
        self error: 'conditions size must the same as the choices size' ].
    ^super new
        conditions: cs;
        choices: vs!
!

!ASTIfsOp methodsFor: 'accessing'!

clearAlias
    super clearAlias.
    conditions do: [ :each | each clearAlias ].
    choices do: [ :each | each clearAlias ]!

width
    ^choices inject: 0 into: [ :m :c | m max: c width ]!

conditions 
    ^conditions!

conditions: cs
    conditions := cs!

choices
    ^choices!

choices: vs
    choices := vs!

dependencies
    |all|
    all := conditions inject: #() into: [ :list :each |
        list, each dependencies ].
    ^choices inject: all into: [ :list :each |
        list, each dependencies ]!

isCombinatorial
"return whether the expression is fully dependent on all dependencies"
    |v|
    choices do: [ :each | each isCombinatorial ifFalse: [ ^false ]].
    v := conditions last staticValue.
    ^v notNil and: [ v > 0]!
!

!ASTIfsOp methodsFor: 'basic'!

checkDesign
    |w result c cw|
    w := self width.
    1 to: choices size do: [ :i |
        c := choices at: i.
        cw := c width.
        result := c checkDesign & (conditions at: i) checkDesign.
        (cw == 0) | (cw == w) ifFalse: [ result := false ].
        result ifFalse: [ ^false ]].
    ^true!

context: c type: t
    conditions do: [ :each | each context: c type: t ].
    choices do: [ :each | each context: c type: t ]!

destroy
    conditions do: [ :each | each destroy ].
    choices do: [ :each | each destroy ]!

evaluate
    1 to: conditions size do: [ :i |
        (conditions at: i) evaluate > 0 ifTrue: [
            ^(choices at: i) evaluate ]].
    ^nil!

staticValue
    |v|
    1 to: conditions size do: [ :i |
        v := (conditions at: i) staticValue.
        v isNil ifTrue: [ ^ nil ].
        v > 0 ifTrue: [ ^(choices at: i) staticValue ]].
    ^nil!

optimize
    |w last text c v ch|
    text := self printString.
    choices := choices collect: [ :each | each optimize ].
    conditions := conditions collect: [ :each | each optimize ].
    w := self width.
    last := false.
    1 to: conditions size do: [ :i |
        c := conditions at: i.
        ch := choices at: i.
        v := c staticValue.
        (last or: [v notNil and: [ v = 0 ]]) ifTrue: [
            c destroy.
            ch destroy.
            conditions at: i put: nil.
            choices at: i put: nil ].
        (v notNil and: [ v > 0 ]) ifTrue: [ last := true ]].
    choices := choices select: [ :each | each notNil ].
    conditions := conditions select: [ :each | each notNil ].
    choices size == 0 ifTrue: [
        Transcript nextPutAll: 'Error: %1 is optimized to nil' % {text}; nl ].
    choices size == 1 ifTrue: [ 
        v := (conditions at: 1) staticValue.
        (v notNil and: [ v > 0 ]) ifTrue: [ 
            ch := choices at: 1.
            ch width == 0 ifTrue: [ ch width: w ].
            ^ch ]]!
!

!ASTIfsOp methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
    conditions do: [ :c |
        c printAdditionalVerilogOn: aStream ].
    choices do: [ :c |
        c printAdditionalVerilogOn: aStream ]!

printVerilogOn: aStream
    |deps|
    self printVerilogRegsOn: aStream.
    deps := conditions inject: #() into: [ :list :each |
        list, each dependencies].
    deps := choices inject: deps into: [ :list :each |
        list, each dependencies].
    DANMExpressionWire printDependencies: deps uniquify on: aStream.
    self printCoreVerilogOn: aStream indent: 8 blocking: true!

printCoreVerilogOn: aStream indent: num blocking: blocking wrapping: wrapping
    |e c v|
    wrapping ifTrue: [
        aStream 
            next: num-2 put: $ ;
            nextPutAll: 'begin'; nl ].
    1 to: conditions size do: [ :i |
        c := conditions at: i.
        aStream 
            next: num put: $ .
        i == 1 
            ifTrue: [ 
                aStream 
                    nextPutAll: 'if (%1)' % 
                        {c printStringStyle: #VERILOG}; nl ]
            ifFalse: [
                v := c staticValue.
                (v notNil and: [ v > 0 ])
                    ifTrue: [ aStream nextPutAll: 'else'; nl ]
                    ifFalse: [
                        aStream 
                            nextPutAll: 'else if (%1)' % 
                            {(conditions at: i) printStringStyle: #VERILOG}; 
                            nl ]].
        e := choices at: i.
        e alias: alias.
        e printCoreVerilogOn: aStream indent: num+4 
          blocking: blocking wrapping: true ].
    wrapping ifTrue: [
        aStream 
            next: num-2 put: $ ;
            nextPutAll: 'end'; nl ]!
    
basicPrintStringStyle: style
    "verilog style is covered in printVerilogOn: so I assume html and none
     style"
    |aStream|
    aStream := WriteStream on: String new.
    style == #HTML ifTrue: [
        aStream nextPutAll: 'Ifs:<br/><table  border="1"><tr><th>condition</th><th>value</th></tr>'; nl.
        1 to: conditions size do: [ :i |
            aStream nextPutAll: '<tr><td>%1</td><td>%2</td></tr>' % 
                {(conditions at: i) basicPrintStringStyle: #HTML.
                 (choices at: i) basicPrintStringStyle: #HTML} ].
        aStream 
            nextPutAll: '</table>'; nl ].
    style == #NONE ifTrue: [
        aStream nextPutAll: 'Ifs{'.
        1 to: conditions size do: [ :i |
            aStream nextPutAll: '%1->%2.' % 
                {(conditions at: i) basicPrintStringStyle: #NONE.
                 (choices at: i) basicPrintStringStyle: #NONE} ].
        aStream 
            nextPutAll: '}' ].
        ^aStream contents!
!

ExpressionAST subclass: #ASTCasesOp
              instanceVariableNames: 'subject cases choices'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTCasesOp comment: 
    'I model a mux in a switch-case statement, like 
    case (a) 
        1: b = d;
        c: b = f;
    endcase
I cannot be sub expression to some other expression though. '!

!ASTCasesOp class methodsFor: 'instance creation'!

newCases: table on: subject
    |e cases choices|
    cases := OrderedCollection new.
    choices := OrderedCollection new.
    e := ExpressionAST newFrom: subject.
    table do: [ :each |
        |c v|
        c := ExpressionAST newFrom: each key.
        v := ExpressionAST newFrom: each value.
        cases add: c.
        choices add: v.
        (c isKindOf: ASTDefault) ifTrue: [
            ^self newSubject: e cases: cases choices: choices ]].
    ^self newSubject: e cases: cases choices: choices!

newSubject: s cases: cs choices: vs
    cs size == vs size ifFalse: [
        self error: 'cases size must the same as the choices size' ].
    ^super new
        subject: s;
        cases: cs;
        choices: vs!
!

!ASTCasesOp methodsFor: 'accessing'!

clearAlias
    super clearAlias.
    subject clearAlias.
    cases do: [ :each | each clearAlias ].
    choices do: [ :each | each clearAlias ]!


width
    ^choices inject: 0 into: [ :m :c | m max: c width ]!

subject
    ^subject!

subject: s
    subject := s!

cases 
    ^cases!

cases: cs
    cases := cs!

choices
    ^choices!

choices: vs
    choices := vs!

dependencies
    |all|
    all := cases inject: subject dependencies into: [ :list :each |
        list, each dependencies ].
    ^choices inject: all into: [ :list :each |
        list, each dependencies ]!

isCombinatorial
"return whether the expression is fully dependent on all dependencies"
    choices do: [ :each | each isCombinatorial ifFalse: [ ^false ]].
    ^(cases last isKindOf: ASTDefault) | 
        (cases size == (1 bitShift: subject width))!
!

!ASTCasesOp methodsFor: 'basic'!

checkDesign
    |w result c cw|
    subject checkDesign ifFalse: [ ^false ].
    w := self width.
    1 to: choices size do: [ :i |
        c := choices at: i.
        cw := c width.
        result := c checkDesign & (cases at: i) checkDesign.
        (cw == 0) | (cw == w) ifFalse: [ result := false ].
        result ifFalse: [ ^false ]].
    ^true!

context: c type: t
    subject context: c type: t.
    cases do: [ :each | each context: c type: t ].
    choices do: [ :each | each context: c type: t ]!

destroy
    subject destroy.
    cases do: [ :each | each destroy ].
    choices do: [ :each | each destroy ]!

evaluate
    |v c vc|
    v := subject evaluate.
    1 to: cases size do: [ :i |
        c := cases at: i.
        vc := c evaluate.
        vc isNil | (vc == v) ifTrue: [ 
            ^(choices at: i) evaluate ]].
    ^nil!

staticValue
    |v c vc|
    v := subject staticValue.
    v isNil ifTrue: [ ^nil ].
    1 to: cases size do: [ :i |
        c := cases at: i.
        (c isKindOf: ASTDefault) ifTrue: [
            ^(choices at: i) staticValue ].
        vc := c staticValue.
        vc isNil ifTrue: [ ^nil ].
        vc == v ifTrue: [ 
            ^(choices at: i) staticValue ]].
    ^nil!

optimize
    |v w last result c ch|
    subject := subject optimize.
    v := subject staticValue.
    last := false.
    choices := choices collect: [ :each | each optimize ].
    cases := cases collect: [ :each | each optimize ].
    v isNil ifTrue: [ ^self ].
    w := self width.
    1 to: cases size do: [ :i |
        c := cases at: i.
        ch := choices at: i.
        last ifTrue: [
            c destroy.
            ch destroy ].
        c staticValue = v ifTrue: [ 
            result := ch.
            result width == 0 ifTrue: [ result width: w ].
            last := true ]].
    result notNil ifTrue: [ ^ result ]!
!

!ASTCasesOp methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
    subject printAdditionalVerilogOn: aStream.
    cases do: [ :c |
        c printAdditionalVerilogOn: aStream ].
    choices do: [ :c |
        c printAdditionalVerilogOn: aStream ]!

printVerilogOn: aStream
    |deps|
    self printVerilogRegsOn: aStream.
    deps := cases inject: subject dependencies into: [ :list :each |
        list, each dependencies].
    deps := choices inject: deps into: [ :list :each |
        list, each dependencies].
    DANMExpressionWire printDependencies: deps uniquify on: aStream.
    self printCoreVerilogOn: aStream indent: 8 blocking: true!

printCoreVerilogOn: aStream indent: num blocking: blocking wrapping: wrapping
    |e|
    aStream 
        next: num put: $ ;
        nextPutAll: 'case (%1)' % {subject printStringStyle: #VERILOG}; nl.
    1 to: cases size do: [ :i |
        aStream 
            next: num+4 put: $ ;
            nextPutAll: '%1: ' 
            % {(cases at: i) printStringStyle: #VERILOG}; nl.
        e := choices at: i.
        e alias: alias.
        e printCoreVerilogOn: aStream indent: num+8 
          blocking: blocking wrapping: false ].
    aStream
        next: num put: $ ;
        nextPutAll: 'endcase'; nl!

basicPrintStringStyle: style
    "plain style does not make much sense for me and verilog style is covered 
     in printVerilogOn: so I assume html style"
    |aStream|
    aStream := WriteStream on: String new.
    style == #HTML ifTrue: [
        aStream nextPutAll: 'Cases on %1:<br/><table  border="1"><tr><th>case</th><th>value</th></tr>' % {subject basicPrintStringStyle: #HTML}; nl.
        1 to: cases size do: [ :i |
            aStream nextPutAll: '<tr><td>%1</td><td>%2</td></tr>' % 
                {(cases at: i) basicPrintStringStyle: #HTML.
                 (choices at: i) basicPrintStringStyle: #HTML} ].
        aStream 
            nextPutAll: '</table>'; nl ].
    style == #NONE ifTrue: [
        aStream nextPutAll: 'Cases(%1){' % 
            {subject basicPrintStringStyle: #NONE}.
        1 to: cases size do: [ :i |
            aStream nextPutAll: '%1->%2.' % 
                {(cases at: i) basicPrintStringStyle: #NONE.
                 (choices at: i) basicPrintStringStyle: #NONE} ].
        aStream 
            nextPutAll: '}' ].
    ^aStream contents!
!

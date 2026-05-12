Class {
	#name : 'AbUiConstants',
	#superclass : 'Object',
	#classInstVars : [
		'icons'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'class initialization' }
AbUiConstants class >> initialize [

	icons := nil
]

{ #category : 'actions' }
AbUiConstants class >> iconNamed: iconNameSymbol [

	^ [ self perform: iconNameSymbol ] on: MessageNotUnderstood do: [:ex | ex return: nil ]
]

{ #category : 'accessing' }
AbUiConstants class >> icons [

	^ icons ifNil: [ icons := Dictionary new ]
]

{ #category : 'private' }
AbUiConstants class >> buildIconNamed: iconName with: base64String [
    ^ Form fromBase64String: base64String
]

{ #category : 'icons-base64' }
AbUiConstants class >> blueCircleBase64 [

^ 'iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+oFDA0dO7+CtOcAAAD4SURBVCjPlZExTsNgDIU//2nE0FN06JQpLIEqnWHpDdhRpeQAnQhDT1BELtCeoBN7iejEkiww5BQM0CRm+RNFqJXoG+3P1vOzYHV93wwHFxKj3CF4tlwA66Zi9fosXwACMJnryHF5AcYc12d94CZLpZTJXIeOy3sHK3uFrQVnIgS9IX/guMQtrA2PuydJepuXYaSJGB6AseMSyzTWHMFTZb9bydUxP9NY3xAClML0Dtye8E9nUfAMZ8qgFDau2Smo6ym5QVjbahBGmvyFw0gT2qSEzVmxVj/q//dxH/WB2yyV0gBkqZTVt/rAor3JKgcWTc1llkoJ8AuoyF0RH/AVsAAAAABJRU5ErkJggg=='
]

{ #category : 'icons-base64' }
AbUiConstants class >> checkBase64 [

^ 'iVBORw0KGgoAAAANSUhEUgAAAAwAAAAJCAYAAAAGuM1UAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB+oFDAsvNMbAgbUAAAEeSURBVBjTjZA9S8NgFIXPfZPUYAIxJK3tpAiuLtLJIrSilA6ujsW6KPQ/iDgrKEigiCAuQhczNBUUCoIW/AmuTkYy6NAQm+Q6VaSIeqYzPHA+CP9Q1lktCVW5JEGe9Cd8urYg6eoNKbLNcZqh32DrpDwrm/o9kSgwEPDgY0kYe4tT+YtacRw2j5bzsqHdQlCBOR3Ewfu6v9V9EupMrs2SeMyd1zzruKIDgH1Q0ZSs4UIScwAn6TDdCJq9PgAIMFyAmBSpKlta3zwszQtbvSKiIgAkb+HOa73TGSUTANjOSkMyJh0QFDAiEE2ACBwNd/26t/+96tfo6bNqGRnZhSAdADiKW/5md3t8mxiZl8Z1j8OohDS9Q8Kt8OG5+dNzn5q1WI+tuMaEAAAAAElFTkSuQmCC'
]

{ #category : 'icons-base64' }
AbUiConstants class >> greenCircleBase64 [

^ 'iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+oFDAwGBk8eWVsAAACNSURBVCjPldGxEYJQEIThD1OaoABjbMIYrEHa8fWgxFaBqQXQhDEGPgQVGdjsbva/ubtlpZKP6iKTqJDHzk3npNT+ArU9zki/hj5wULgOQC3DfcI8QJ2tUruJjWrGDGlcVQ/kC+7Nx8Bi9UCzwNuMgRC/YeboMACFFuUf6PXWmMVUcEfs3mt0wji41XoCv7wfF3XZGAgAAAAASUVORK5CYII='
]

{ #category : 'icons-base64' }
AbUiConstants class >> questionBase64 [

^ 'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAMCAYAAABfnvydAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB+oFDAs7MgEN89UAAAD0SURBVBjTXY8xS8NgGISf92tsK4VOgmMnpVQKXbV2EEd/geDk5uLmH3B0dRD/gIKbOIhzoouLuJjBSaqC1UUwhES/c6k26Y13x3OcAaSr982qVfdAy0AGXHl0HISd1JL+XXPW1W+BRQoSuvHya67uajvj8Dzx6VymfF7owrAVoS0naAF862e3cd37qEXdN+AAwFmlHxjse3Q5Ey09TfBsGGAwtNLuIK4KHRm2DXxmytuuWPDocBw+Cq3Xou7rNCEHvoAFC9sjgGDq2plQXAk7oz+vVPDyp5i9F73/CT942DTsBPCJ0lYj6g1LBKEYeAF7dkwov35nYbjJAM0MAAAAAElFTkSuQmCC'
]

{ #category : 'icons-base64' }
AbUiConstants class >> redCircleBase64 [

^ 'iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+oFDAwDKgCxwf0AAACHSURBVCjPndG9EYJQEATgD1JKILEAY2yCXGuQdrQpTC2ABCqA+Jk8ZlDAebozF9zN7v0tPyJbJj2HjAZVLD0Ct5JupeypB8aB8BHjQP02IXZ+otjZZAocS7o8qpovZCgiRx4LVcK91VKQjFnQJnDb/4+Ofz5j2iFfZi+2jLviNK8RuG8al4oXTvkqNtSSo28AAAAASUVORK5CYII='
]

{ #category : 'icons-base64' }
AbUiConstants class >> sparkleBase64 [

 ^ 'iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oFDAsrLyjJjV0AAACmSURBVCjPjZAxCsJAEEXfhlQGG1NZWO1VrPQc8T6pFASbXEEb8SpTWdjZBExjGJtVlmRWffBhhz/8/btgoEKlQmV5GTaroBHOSJ8B1zAunOf+64YamATVpFChVKFRQQdqVCg/lVTYAGtgGVItHsAFOGVABzyBnjR92OniSoUKe6PSVoXi21sO0fLun2+dArcwzp2njf18lOBpVTi/z0M/TzQ7piq/ADKAUgjKJidIAAAAAElFTkSuQmCC'
 ]

{ #category : 'icons' }
AbUiConstants class >> blueCircle [
    ^ self icons at: #blueCircle ifAbsentPut: [ self buildIconNamed: #blueCircle with: self blueCircleBase64 ]
]

{ #category : 'icons' }
AbUiConstants class >> redCircle [
    ^ self icons at: #redCircle ifAbsentPut: [ self buildIconNamed: #redCircle with: self redCircleBase64 ]
]

{ #category : 'icons' }
AbUiConstants class >> greenCircle [
    ^ self icons at: #greenCircle ifAbsentPut: [ self buildIconNamed: #greenCircle with: self greenCircleBase64 ]
]

{ #category : 'icons' }
AbUiConstants class >> check [
    ^ self icons at: #check ifAbsentPut: [ self buildIconNamed: #check with: self checkBase64 ]
]

{ #category : 'icons' }
AbUiConstants class >> question [
    ^ self icons at: #question ifAbsentPut: [ self buildIconNamed: #question with: self questionBase64 ]
]

{ #category : 'icons' }
AbUiConstants class >> sparkle [
    ^ self icons at: #sparkle ifAbsentPut: [ self buildIconNamed: #sparkle with: self sparkleBase64 ]
]

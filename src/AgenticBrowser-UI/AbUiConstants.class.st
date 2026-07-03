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

{ #category : 'icons-base64' }
AbUiConstants class >> gearBase64 [

 ^ 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+oFGg46IwEfKM4AAAJKSURBVDjLrZOxSxtxFMc/7xclOS2cXkz0QkAHS4cKXVw61T+gdJBChVK3ltKltShNmqHXIc0Ngl2EDrpYqE5C/wM3F5eCpRQcKoScRqPcEE+R3OtgoosupW98/N77ve/7fp5wQ+RnNlPYeQuAsBpVF+6fXvdOrku63pYl1sgukGmnDjT6Mxx449GNDQZnf/QkBnJfEWkoeiwwq614EkASZl1hXpB+VNOtw9qz/fl7JwBdnQaJgdyKCg8EbQK2xloK3g9+B3Ar9RJGCqChCr2JgdwK8BjAXM0iRwJNs7dzJ4gW+4Ni1sfbSOBtJIJi1g+ixX6zt3NHoInIUafMdDSjeqRgV+2zc4ent1y/vpxLjYW51FiY8+tL6ZOp3qp9dq5go3rkelsWgMnPbKbEGtlFmCNWH2+ilUzZnwXzUFVfK/oGMY+SjrOAN9EiVh9hTqyR3fzMZsq0rcpoK57sjC2YJ4qWgmJmOShkljRulRAz1ZHTXm4GO2+ZmzhA40uHVK63+8KFsBph3T6QhFl3K/VSUMz6+PVVMYmyW9lve23KKN/wJlpupV4QI2XggLAaySU4qeEPKrwMop/p9MmQlXScBcRMtT9aPWscvm307EWudbchyhc93f0YeOORAQi88QgRRyDMh8nuRs9as1bIPq9F2321aLuv9m7gRaNnrZkPk90CISJOh8quK83qqNAbD43+dhm1qbzyg2LWb4NUwEghtggVekXVudpBO1qHtekOyqDHYqTsftr/BSBGygrzIP1ygfL0/z+mfz3nv3sPCvgL1MQbAAAAAElFTkSuQmCC'
]

{ #category : 'icons-base64' }
AbUiConstants class >> boxSelectionBase64 [

 ^ 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+oFGg8IJHPJgysAAAE8SURBVDjLzZMxawJBEIXfGzyvCZITjpz3EwxpEsFWMBD/SypJEe2uW1OkzH+RkMI2SGzE/AQvRnCDpNHAbgr3xFgdXJNX7cCbtzPwDZEkjMq3HRGcwMnS6PT+7AUHqj0srmklyGpj8P2xfRoyUp83IjLEkazZXqX9eAIANTW/pJTfjj3GmE5JyAoAWGtfCYzc+yvY6GnqjMFGT7Uf9kmeAoAFWiSbQlZKWRqB0bwX9rI6PfjpPTn/ATDI6niwHABoAoCgoATWrNzYq7xNe6/rRaTSRj2ZeXkD6snMi1TawP9RkRUkVou2iDfWftjNG6D9sCvijWO1aAsoVQAgWc0bsPdSqoU52JNogZYjzKG8fHQEop7MPO2Hd39QzgKMtWshQbKZ4UkS2g+eAUx2OwcXFFEH2O+Oydo1i57zLz7/iWRNmmChAAAAAElFTkSuQmCC'
]

{ #category : 'icons-base64' }
AbUiConstants class >> fileAttachmentBase64 [

 ^ 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAOwA7ADsHSMWNgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+oHAwYfC4WbSh4AAAC2SURBVDjLY2CgJZDseCYr2fFMFp8aRnyaGRjYbkJ4v9SfV0g9xqaOCZcBTH+ZlBkZGTgZGRk4mf4yKeNUR6k3KTaABcXPjMzqMP7//wz6cDYzo7Fk50u4Wob/f2/CwoQROcAYGRk4ibH1/3+G77CApdgLjLi8wPifQZ+BkbkH6uSS/4wMF3F6ARuQbn3h8J+FZT8DAwMD458/jk+rJQ4M8mhEB/+Y/91l+M/wHRKN/+7SLDNRDAAGo0CogpZhGAAAAABJRU5ErkJggg=='
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

{ #category : 'icons' }
AbUiConstants class >> gear [
    ^ self icons at: #gear ifAbsentPut: [ self buildIconNamed: #gear with: self gearBase64 ]
]

{ #category : 'icons' }
AbUiConstants class >> boxSelection [
    ^ self icons at: #boxSelection ifAbsentPut: [ self buildIconNamed: #boxSelection with: self boxSelectionBase64 ]
]

{ #category : 'icons' }
AbUiConstants class >> fileAttachment [
    ^ self icons at: #fileAttachment ifAbsentPut: [ self buildIconNamed: #fileAttachment with: self fileAttachmentBase64 ]
]

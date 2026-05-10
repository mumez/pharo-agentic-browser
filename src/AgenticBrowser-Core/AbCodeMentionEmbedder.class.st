Class {
	#name : 'AbCodeMentionEmbedder',
	#superclass : 'Object',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'operations' }
AbCodeMentionEmbedder class >> resourcesFor: mentions [

	^ mentions inject: OrderedCollection new into: [ :acc :mention |
		[ acc add: (self resourceFor: mention) ]
			on: Error
			do: [ :e | "skip mentions that can't be resolved" ].
		acc ]
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> resourceFor: mention [

	^ mention isClassMention
		ifTrue: [ self classResourceFor: mention ]
		ifFalse: [ self methodResourceFor: mention ]
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> classResourceFor: mention [

	| className cls url tonel |
	className := mention className.
	cls := Smalltalk globals at: className asSymbol.
	url := 'http://localhost:8086/get-class-source?class_name=' , className.
	tonel := TonelWriter sourceCodeOf: cls.
	^ url -> tonel
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> methodResourceFor: mention [

	| className methodName isClassSide cls url tonel |
	className := mention className.
	methodName := mention methodName.
	isClassSide := mention isClassSide.
	cls := Smalltalk globals at: className asSymbol.
	isClassSide ifTrue: [ cls := cls class ].
	url := 'http://localhost:8086/get-method-source?class_name=' , className
		, '&method_name=' , methodName
		, '&is_class_method=' , isClassSide printString.
	tonel := String streamContents: [ :str |
		TonelWriter new
			writeMethodDefinition: ((cls >> methodName asSymbol) asMCMethodDefinition)
			on: str ].
	^ url -> tonel
]

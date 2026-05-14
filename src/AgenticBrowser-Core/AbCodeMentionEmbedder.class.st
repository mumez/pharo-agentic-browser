Class {
	#name : 'AbCodeMentionEmbedder',
	#superclass : 'Object',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'private' }
AbCodeMentionEmbedder class >> classResourceFor: mention [

	| className cls url tonel |
	className := mention className.
	cls := Smalltalk globals at: className asSymbol.
	url := '{1}/get-class-source?class_name={2}' format: { self mcpBaseUrl. className }.
	tonel := TonelWriter sourceCodeOf: cls.
	^ url -> tonel
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> mcpBaseUrl [

	^ 'http://localhost:8086'
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> methodResourceFor: mention [

	| className methodName isClassSide cls url tonel |
	className := mention className.
	methodName := mention methodName.
	isClassSide := mention isClassSide.
	cls := Smalltalk globals at: className asSymbol.
	isClassSide ifTrue: [ cls := cls class ].
	url := '{1}/get-method-source?class_name={2}&method_name={3}&is_class_method={4}' format: { self mcpBaseUrl. className. methodName. isClassSide printString }.
	tonel := String streamContents: [ :str |
		TonelWriter new
			writeMethodDefinition: ((cls >> methodName asSymbol) asMCMethodDefinition)
			on: str ].
	^ url -> tonel
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> resourceFor: mention [

	^ mention isClassMention
		ifTrue: [ self classResourceFor: mention ]
		ifFalse: [ self methodResourceFor: mention ]
]

{ #category : 'operations' }
AbCodeMentionEmbedder class >> resourcesFor: mentions [

	^ mentions inject: OrderedCollection new into: [ :acc :mention |
		[ acc add: (self resourceFor: mention) ]
			on: Error
			do: [ :e | "skip mentions that can't be resolved" ].
		acc ]
]

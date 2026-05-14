Class {
	#name : 'AbCodeMention',
	#superclass : 'Object',
	#instVars : [
		'className',
		'methodName',
		'isClassSide'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbCodeMention class >> className: aString [

	^ self new
		className: aString;
		methodName: nil;
		isClassSide: false;
		yourself
]

{ #category : 'instance creation' }
AbCodeMention class >> className: aString methodName: aMethod isClassSide: aBool [

	^ self new
		className: aString;
		methodName: aMethod;
		isClassSide: aBool;
		yourself
]

{ #category : 'accessing' }
AbCodeMention >> className [
	^ className
]

{ #category : 'accessing' }
AbCodeMention >> className: aString [
	className := aString
]

{ #category : 'testing' }
AbCodeMention >> isClassMention [
	^ self methodName isNil
]

{ #category : 'accessing' }
AbCodeMention >> isClassSide [
	^ isClassSide
]

{ #category : 'accessing' }
AbCodeMention >> isClassSide: aBoolean [
	isClassSide := aBoolean
]

{ #category : 'testing' }
AbCodeMention >> isMethodMention [
	^ self methodName notNil
]

{ #category : 'accessing' }
AbCodeMention >> methodName [
	^ methodName
]

{ #category : 'accessing' }
AbCodeMention >> methodName: aString [
	methodName := aString
]

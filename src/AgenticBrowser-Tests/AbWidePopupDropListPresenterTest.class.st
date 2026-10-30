Class {
	#name : 'AbWidePopupDropListPresenterTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'presenter',
		'window'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'accessing' }
AbWidePopupDropListPresenterTest >> presenter [

	^ presenter
]

{ #category : 'accessing' }
AbWidePopupDropListPresenterTest >> presenter: aPresenter [

	presenter := aPresenter
]

{ #category : 'accessing' }
AbWidePopupDropListPresenterTest >> window [

	^ window
]

{ #category : 'accessing' }
AbWidePopupDropListPresenterTest >> window: aWindowPresenter [

	window := aWindowPresenter
]

{ #category : 'running' }
AbWidePopupDropListPresenterTest >> setUp [

	super setUp.
	self presenter: AbWidePopupDropListPresenter new
]

{ #category : 'running' }
AbWidePopupDropListPresenterTest >> tearDown [

	self window ifNotNil: [ :openWindow |
		self dropListMorph hideList.
		openWindow close ].
	super tearDown
]

{ #category : 'accessing' }
AbWidePopupDropListPresenterTest >> dropListMorph [

	^ self presenter adapter widget
]

{ #category : 'running' }
AbWidePopupDropListPresenterTest >> openWindowOfExtent: aPoint [
	"Morph bounds and the World are only available with a real display, so callers skip headless runs first."

	self window: self presenter open.
	self window adapter widget
		extent: aPoint;
		fullBounds
]

{ #category : 'tests' }
AbWidePopupDropListPresenterTest >> testBuildsWidePopupDropListMorph [

	self presenter build.
	self assert: self dropListMorph class equals: AbWidePopupDropListMorph
]

{ #category : 'tests' }
AbWidePopupDropListPresenterTest >> testPopupListWidensToFitWidestItem [

	| widestItem font |
	SmalltalkImage current isInteractiveGraphic ifFalse: [ ^ self skip ].
	widestItem := 'smalltalk-dev:smalltalk-implementation-finder'.
	self presenter items: { 'st-buddy'. widestItem }.
	self openWindowOfExtent: 160 @ 100.
	self dropListMorph showList.
	self dropListMorph listMorph fullBounds.
	font := self dropListMorph listMorph font.
	self assert: self dropListMorph listMorph width > self dropListMorph width.
	self assert: self dropListMorph listMorph width >= (font widthOfString: widestItem).
	"Pins popupListPadding: a theme or font change that makes it too small brings the horizontal scrollbar back."
	self deny: self dropListMorph listMorph hIsScrollbarShowing
]

{ #category : 'tests' }
AbWidePopupDropListPresenterTest >> testPopupListWidensWhenOpeningAbove [
	"A status bar at the bottom of a low window has little room below, so DropListMorph>>positionList opens the popup above the button."

	SmalltalkImage current isInteractiveGraphic ifFalse: [ ^ self skip ].
	self presenter items: ((1 to: 10) collect: [ :index |
			 'smalltalk-dev:smalltalk-implementation-finder-' , index printString ]).
	self openWindowOfExtent: 160 @ 100.
	self window adapter widget
		position: 100 @ (self currentWorld bottom - 100);
		fullBounds.
	self dropListMorph showList.
	self assert: self dropListMorph listMorph bottom <= self dropListMorph boundsInWorld top.
	self assert: self dropListMorph listMorph width > self dropListMorph width
]

{ #category : 'tests' }
AbWidePopupDropListPresenterTest >> testPopupListKeepsButtonWidthForShortItems [

	SmalltalkImage current isInteractiveGraphic ifFalse: [ ^ self skip ].
	self presenter items: #( 'plan' 'code' ).
	self openWindowOfExtent: 300 @ 100.
	self dropListMorph showList.
	self assert: self dropListMorph listMorph width equals: self dropListMorph width
]

{ #category : 'tests' }
AbWidePopupDropListPresenterTest >> testPopupListStaysInsideWorld [

	SmalltalkImage current isInteractiveGraphic ifFalse: [ ^ self skip ].
	self presenter items: { 'smalltalk-dev:smalltalk-implementation-finder' }.
	self openWindowOfExtent: 160 @ 100.
	self window adapter widget
		position: (self currentWorld right - 160) @ 100;
		fullBounds.
	self dropListMorph showList.
	self assert: self dropListMorph listMorph right <= self currentWorld right
]

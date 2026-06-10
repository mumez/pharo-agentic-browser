Class {
	#name : 'BaselineOfAgenticBrowser',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfAgenticBrowser',
	#package : 'BaselineOfAgenticBrowser'
}

{ #category : 'baselines' }
BaselineOfAgenticBrowser >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			baseline: 'ACP'
			with: [ spec repository: 'github://mumez/pharo-acp:main/src' ].
		spec
			baseline: 'SState'
			with: [ spec repository: 'github://mumez/SState/src' ].
		spec
			baseline: 'PharoSmalltalkInteropServer'
			with: [ spec repository: 'github://mumez/PharoSmalltalkInteropServer:main/src' ].
		spec
			baseline: 'Ripple'
			with: [
				spec
					repository: 'github://mumez/Ripple:main/src';
					loads: #( 'Core' ) ].
		spec
			package: 'AgenticBrowser-Core'
			with: [ spec requires: #( 'ACP' 'SState' 'PharoSmalltalkInteropServer' ) ].
		spec
			package: 'AgenticBrowser-Handler'
			with: [ spec requires: #( 'AgenticBrowser-Core' 'ACP' ) ].
		spec
			package: 'AgenticBrowser-UI'
			with: [ spec requires: #( 'AgenticBrowser-Handler' ) ].
		spec
			package: 'AgenticBrowser-Tests'
			with: [ spec requires: #( 'AgenticBrowser-Core' 'AgenticBrowser-Handler' ) ].
		spec
			package: 'AgenticBrowser-WebUI'
			with: [ spec requires: #( 'AgenticBrowser-Core' 'Ripple' ) ].
		spec
			package: 'AgenticBrowser-WebUI-Tests'
			with: [ spec requires: #( 'AgenticBrowser-WebUI' 'AgenticBrowser-Tests' ) ].
		spec
			group: 'default'
			with: #( 'AgenticBrowser-Core' 'AgenticBrowser-Handler' 'AgenticBrowser-UI' ).
		spec
			group: 'Tests'
			with: #( 'default' 'AgenticBrowser-Tests' ).
		spec
			group: 'WebUI'
			with: #( 'AgenticBrowser-WebUI' ).
		spec
			group: 'WebUI-Tests'
			with: #( 'AgenticBrowser-WebUI' 'AgenticBrowser-WebUI-Tests' ) ]
]

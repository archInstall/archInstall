#!/usr/bin/env coffee
# -*- coding: utf-8 -*-

# region header

###
[Project page](http://torben.website/jQuery-lang)

This plugin provided client side internationalisation support for websites.

Copyright Torben Sickert 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de

Extending this module
---------------------

For conventions see require on https://github.com/thaibault/require

Author
------

t.sickert["~at~"]gmail.com (Torben Sickert)

Version
-------

1.0 stable
###

main = ($) ->

# endregion

# region plugins/classes

    class Lang extends $.Tools.class
        ###
            This plugin holds all needed methods to extend a website for
            internationalisation.
        ###

    # region properties

        ###
            **__name__ {String}**
            Holds the class name to provide inspection features.
        ###
        __name__: 'Lang'

    # endregion

    # region public methods

        # region special

        initialize: (
            options={}, @currentLanguage='', @knownLanguage={}
            @_$domNodeToFade=null, @_replacements=[]
            @_textNodesWithKnownLanguage={}
        ) ->
            ###
                Initializes the plugin. Current language is set and later
                needed dom nodes are grabbed.

                **options {Object}** - An options object.

                **returns {$.Lang}** - Returns the current instance.
            ###
            ###
                **_options {Object}**
                Saves default options for manipulating the Gui's behaviour.
            ###
            this._options =
                domNodeSelectorPrefix: 'body'
                default: 'enUS'
                allowedLanguages: []
                initial: null
                domNodeClassPrefix: ''
                templateDelimiter:
                    pre: '{{', post: '}}'
                fadeEffect: true
                textNodeParent:
                    fadeIn: duration: 'fast'
                    fadeOut: duration: 'fast'
                preReplacementLanguagePattern: '^\\|({1})$'
                replacementLanguagePattern: '^([a-z]{2}[A-Z]{2}):((.|\\s)*)$'
                currentLanguagePattern: '^[a-z]{2}[A-Z]{2}$'
                replacementDomNodeName: ['#comment', 'langreplacement']
                replaceDomNodeNames: ['#text', 'langreplace']
                toolsLockDescription: '{1}Switch'
                languageHashPrefix: 'lang-'
                currentLanguageIndicatorClassName: 'current'
                sessionDescription: '{1}'
                languageMapping:
                    deDE: ['de', 'de_de', 'de-de', 'german', 'deutsch']
                    enUS: ['en', 'en_us', 'en-us']
                    enEN: ['en_en', 'en-en', 'english']
                    frFR: ['fr', 'fr_fr', 'fr-fr', 'french']
                onSwitched: $.noop()
                onEnsureded: $.noop()
                onSwitch: $.noop()
                onEnsure: $.noop()
                domNode: knownLanguage: 'div.toc'
            super options
            this._options.preReplacementLanguagePattern = this.stringFormat(
                this._options.preReplacementLanguagePattern,
                this._options.replacementLanguagePattern.substr(
                    1, this._options.replacementLanguagePattern.length - 2))
            this._options.toolsLockDescription = this.stringFormat(
                this._options.toolsLockDescription, this.__name__)
            this._options.sessionDescription = this.stringFormat(
                this._options.sessionDescription, this.__name__)
            this.$domNodes = this.grabDomNode this._options.domNode
            this.$domNodes.switchLanguageButtons = $(
                "a[href^=\"##{this._options.languageHashPrefix}\"]")
            this._movePreReplacementNodes()
            this.currentLanguage = this._normalizeLanguage(
                this._options.default)
            # NOTE: Only switch current language indicator if we haven't an
            # initial language switch which will perform the indicator switch.
            newLanguage = this._determineUsefulLanguage()
            if this.currentLanguage is newLanguage
                this._switchCurrentLanguageIndicator newLanguage
            else
                this.switch newLanguage, true
            this.on this.$domNodes.switchLanguageButtons, 'click', (event) =>
                event.preventDefault()
                this.switch $(event.target).attr('href').substr(
                    this._options.languageHashPrefix.length + 1)
            this

        # endregion

        switch: (language, ensure=false) ->
            ###
                Switches the current language to given language. This method is
                mutual synchronized.

                **language {String|Boolean}** - New language as string or
                                                "true". If set to "true" it
                                                indicates that the dom tree
                                                should be checked again current
                                                language to ensure every text
                                                node has right content.

                **ensure {Boolean}**          - Indicates if a switch effect
                                                should be avoided.

                **returns {$.Lang}**  - Returns the current instance.
            ###
            if(language isnt true and this._options.allowedLanguages.length and
               $.inArray(language, this._options.allowedLanguages) is -1)
                this.debug(
                    '"{1}" isn\'t one of the allowed languages.', language)
                return this
            this.acquireLock this._options.toolsLockDescription, =>
                if language is true
                    ensure = true
                    language = this.currentLanguage
                else
                    language = this._normalizeLanguage language
                if(ensure and language isnt this._options.default or
                   this.currentLanguage isnt language)
                    actionDescription = 'Switch to'
                    actionDescription = 'Ensure' if ensure
                    this.debug '{1} "{2}".', actionDescription, language
                    this._switchCurrentLanguageIndicator language
                    this.fireEvent(
                        (if ensure then 'ensure' else 'switch'), true, this,
                        this.currentLanguage, language)
                    this._$domNodeToFade = null
                    this._replacements = []
                    [$lastTextNodeToTranslate, $lastLanguageDomNode] =
                        this._collectTextNodesToReplace language, ensure
                    this._checkLastTextNodeHavingLanguageIndicator(
                        $lastTextNodeToTranslate, $lastLanguageDomNode,
                        ensure)
                    this._handleSwitchEffect language, ensure
                else
                    this.debug(
                        '"{1}" is already current selected language.',
                        language)
                    this.releaseLock this._options.toolsLockDescription
            this
        refresh: ->
            ###
                Ensures current selected language.

                **returns {$.Lang}** - Returns the current instance.
            ###
            this._movePreReplacementNodes().switch true

    # endregion

    # region protected methods

        _movePreReplacementNodes: ->
            ###
                Moves pre replacement dom nodes into next dom node behind
                translation text to use the same translation algorithm for
                both.

                **returns {$.Lang}** - Returns the current instance.
            ###
            self = this
            this.$domNodes.parent.find(':not(iframe)').contents().each ->
                $this = $ this
                nodeName = $this.prop('nodeName').toLowerCase()
                if $.inArray(
                    nodeName, self._options.replacementDomNodeName
                ) isnt -1
                    if $.inArray(nodeName, ['#comment', '#text']) is -1
                        # NOTE: Hide replacement dom nodes.
                        $this.hide()
                    regex = new RegExp(
                        self._options.preReplacementLanguagePattern)
                    match = $this.prop('textContent').match regex
                    if match and match[0]
                        $this.prop 'textContent', $this.prop(
                            'textContent'
                        ).replace regex, match[1]
                        selfFound = false
                        $this.parent().contents().each ->
                            if selfFound and $.trim $(this).text()
                                $this.appendTo this
                                return false
                            if $this[0] is this
                                selfFound = true
                            true
            this
        _collectTextNodesToReplace: (language, ensure) ->
            ###
                Collects all text nodes which should be replaced later.

                **language {String}**   - New language.

                **ensure {Boolean}**    - Indicates if the whole dom should be
                                          checked again current language to
                                          ensure every text node has right
                                          content.

                **returns {domNode[]}** - Return a tuple of last text and
                                          language dom node to translate.
            ###
            $currentTextNodeToTranslate = null
            $currentLanguageDomNode = null
            $lastTextNodeToTranslate = null
            $lastLanguageDomNode = null
            this.knownLanguage = {}
            self = this
            this.$domNodes.parent.find(':not(iframe)').contents().each ->
                $currentDomNode = $ this
                nodeName = $currentDomNode.prop('nodeName').toLowerCase()
                if $.inArray(
                    nodeName.toLowerCase(), self._options.replaceDomNodeNames
                ) isnt -1
                    # NOTE: We skip empty and nested text nodes
                    if($.trim($currentDomNode.text()) and
                       $currentDomNode.parents(
                        self._options.replaceDomNodeNames.join()
                    ).length is 0)
                        $lastLanguageDomNode = \
                        self._checkLastTextNodeHavingLanguageIndicator(
                            $lastTextNodeToTranslate, $lastLanguageDomNode,
                            ensure)
                        $currentTextNodeToTranslate = $currentDomNode
                else if $currentTextNodeToTranslate?
                    if $.inArray(
                        nodeName, self._options.replacementDomNodeName
                    ) isnt -1
                        content = $currentDomNode.prop 'textContent'
                        if nodeName isnt '#comment'
                            content = $currentDomNode.html()
                        match = content.match new RegExp(
                            self._options.replacementLanguagePattern)
                        if match and match[1] is language
                            # Save known text translations.
                            self.knownLanguage[$.trim(
                                $currentTextNodeToTranslate.text()
                            )] = $.trim match[2]
                            self._registerTextNodeToChange(
                                $currentTextNodeToTranslate,
                                $currentDomNode, match,
                                $currentLanguageDomNode)
                            $lastTextNodeToTranslate = \
                                $currentTextNodeToTranslate
                            $lastLanguageDomNode = $currentLanguageDomNode
                            $currentTextNodeToTranslate = null
                            $currentLanguageDomNode = null
                        else if $currentDomNode.prop(
                            'textContent'
                        ).match new RegExp self._options.currentLanguagePattern
                            $currentLanguageDomNode = $currentDomNode
                        return true
                    $lastTextNodeToTranslate = null
                    $lastLanguageDomNode = null
                    $currentTextNodeToTranslate = null
                    $currentLanguageDomNode = null
                true
            this._registerKnownTextNodes()
            [$lastTextNodeToTranslate, $lastLanguageDomNode]
        _registerKnownTextNodes: ->
            ###
                Iterates all text nodes in language known area with known
                translations.

                **returns {$.Lang}**  - Returns the current instance.
            ###
            this._textNodesWithKnownLanguage = {}
            self = this
            this.$domNodes.knownLanguage.find(
                ':not(iframe)'
            ).contents().each ->
                $currentDomNode = $ this
                # NOTE: We skip empty and nested text nodes
                if($.inArray(
                    $currentDomNode.prop('nodeName').toLowerCase(),
                    self._options.replaceDomNodeNames
                ) isnt -1 and $.trim($currentDomNode.text()) and
                $currentDomNode.parents(
                    self._options.replaceDomNodeNames.join()
                ).length is 0 and self.knownLanguage[$.trim(
                    $currentDomNode.prop 'textContent')]?
                )
                    self._addTextNodeToFade $currentDomNode
                    if(self._textNodesWithKnownLanguage\
                        [self.knownLanguage[$
                        .trim($currentDomNode.prop('textContent'))]]?
                    )
                        self._textNodesWithKnownLanguage[self.knownLanguage[$
                        .trim($currentDomNode.prop('textContent'))
                        ]].push $currentDomNode
                    else
                        self._textNodesWithKnownLanguage[self.knownLanguage\
                        [$.trim($currentDomNode.prop 'textContent')]] = [
                            $currentDomNode]
            this
        _normalizeLanguage: (language) ->
            ###
                Normalizes a given language string.

                **language {String}** - New language.

                *returns {String}**   - Returns the normalized version of given
                                        language.
            ###
            for key, value of this._options.languageMapping
                if $.inArray(key.toLowerCase(), value) is -1
                    value.push key.toLowerCase()
                if $.inArray(language.toLowerCase(), value) isnt -1
                    return key
            return this._options.default
        _determineUsefulLanguage: ->
            ###
                Determines a useful initial language depending on session and
                browser settings.

                **returns {String}** - Returns the determined language.
            ###
            if this._options.initial?
                result = this._options.initial
            else if window.localStorage?.getItem(
                this._options.sessionDescription
            )?
                result = window.localStorage.getItem(
                    this._options.sessionDescription)
                this.debug(
                    'Determine "{1}", because of local storage information.',
                    result)
            else if navigator.language?
                result = navigator.language
                this.debug(
                    'Determine "{1}", because of browser settings.', result)
            else
                result = this._options.default
                this.debug(
                    'Determine "{1}", because of default option.', result)
            result = this._normalizeLanguage result
            if this._options.allowedLanguages.length and $.inArray(
                result, this._options.allowedLanguages
            ) is -1
                this.debug(
                    '"{1}" isn\'t one of the allowed languages. Set language' +
                    ' to "{2}".', result, this._options.allowedLanguages[0])
                result = this._options.allowedLanguages[0]
            if window.localStorage?
                window.localStorage.setItem(
                    this._options.sessionDescription, result)
            result
        _handleSwitchEffect: (language, ensure) ->
            ###
                Depending an activated switching effect this method initialized
                the effect of replace all text string directly.

                **language {String}** - New language.

                **ensure {Boolean}**  - Indicates if current language should be
                                        ensured again every text node content.

                **returns {$.Lang}**  - Returns the current instance.
            ###
            if(not ensure and this._options.fadeEffect and
               this._$domNodeToFade?)
                $.when(this._$domNodeToFade.fadeOut(
                    this._options.textNodeParent.fadeOut
                ).promise()).always this.getMethod(
                    this._handleLanguageSwitching, this, language, ensure)
            else
                this._handleLanguageSwitching(
                    this._handleLanguageSwitching, this, language, ensure)
            this
        _addTextNodeToFade: ($textNode) ->
            ###
                Registers a text node to change its content with given
                replacement.

                **$textNode {$}**    - Text node with content to translate.

                **returns {$.Lang}** - Returns the current instance.
            ###
            $parent = $textNode.parent()
            if this._$domNodeToFade is null
                this._$domNodeToFade = $parent
            else
                this._$domNodeToFade = this._$domNodeToFade.add $parent
            this
        _registerTextNodeToChange: (
            $currentTextNodeToTranslate, $currentDomNode, match,
            $currentLanguageDomNode
        ) ->
            ###
                Registers a text node to change its content with given
                replacement.

                **$currentTextNodeToTranslate {$}**  - Text node with content
                                                       to translate.

                **$currentDomNode {$}**              - A comment node with
                                                       replacement content.

                **match {String[]}**                 - A matching array of
                                                       replacement's text
                                                       content.

                **$currentLanguageDomNode {$|null}** - A potential given text
                                                       node indicating the
                                                       language of given text
                                                       node.

                **returns {$.Lang}**                 - Returns the current
                                                       instance.
            ###
            this._addTextNodeToFade $currentTextNodeToTranslate
            if $currentDomNode?
                this._replacements.push(
                    $textNodeToTranslate: $currentTextNodeToTranslate
                    $nodeToReplace: $currentDomNode
                    textToReplace: match[2]
                    $currentLanguageDomNode: $currentLanguageDomNode)
            this
        _checkLastTextNodeHavingLanguageIndicator: (
            $lastTextNodeToTranslate, $lastLanguageDomNode, ensure
        ) ->
            ###
                Checks if last text has a language indication comment node.
                This function is called after each parsed dom text node.

                **$lastTextNodeToTranslate {$|null}** - Last text to node to
                                                        check.

                **$lastLanguageDomNode {$|null}**     - A potential given
                                                        language indication
                                                        commend node.

                **ensure {Boolean}**                  - Indicates if current
                                                        language should be
                                                        ensured again every
                                                        text node content.

                **returns {$}**                       - Returns the retrieved
                                                        or newly created
                                                        language indicating
                                                        comment node.
            ###
            if $lastTextNodeToTranslate? and not $lastLanguageDomNode?
                # Last text node doesn't have a current language indicating
                # dom node.
                currentLocalLanguage = this.currentLanguage
                currentLocalLanguage = this._options.default if ensure
                $lastLanguageDomNode = $ "<!--#{currentLocalLanguage}-->"
                $lastTextNodeToTranslate.after $lastLanguageDomNode
            $lastLanguageDomNode
        _handleLanguageSwitching: (thisFunction, self, language, ensure) ->
            ###
                Initialized the language switch and performs an effect if
                specified.

                **thisFunction {Function}** - The function itself.

                **self {$.Lang}**           - The current instance.

                **language {String}**       - The new language to switch to.

                **ensure {Boolean}**        - Indicates if current language
                                              should be ensured again every
                                              text node content.

                **returns {$.Lang}**        - Returns the current instance.
            ###
            oldLanguage = this.currentLanguage
            if(not ensure and this._options.fadeEffect and
               this._$domNodeToFade?)
                this._switchLanguage language
                $.when(this._$domNodeToFade.fadeIn(
                    this._options.textNodeParent.fadeIn
                ).promise()).always =>
                    this.fireEvent(
                        (if ensure then 'ensured' else 'switched')
                        true, this, oldLanguage, language)
                    this.releaseLock this._options.toolsLockDescription
            else
                this._switchLanguage language
                this.fireEvent(
                    (if ensure then 'ensured' else 'switched'), true, this,
                    oldLanguage, language)
                this.releaseLock this._options.toolsLockDescription
            this
        _switchLanguage: (language) ->
            ###
                Performs the low level text replacements for switching to given
                language.

                **language {String}** - The new language to switch to.

                **returns {$.Lang}**  - Returns the current instance.
            ###
            for replacement in this._replacements
                currentText = replacement.$textNodeToTranslate.html()
                if replacement.$textNodeToTranslate.prop('nodeName') is '#text'
                    currentText = replacement.$textNodeToTranslate.prop(
                        'textContent')
                trimmedText = $.trim currentText
                if(not this._options.templateDelimiter or
                   not this.stringEndsWith(
                    trimmedText, this._options.templateDelimiter.post
                  ) and this._options.templateDelimiter.post)
                    if not replacement.$currentLanguageDomNode?
                        # Language note wasn't present initially. So we have to
                        # determine it now.
                        currentDomNodeFound = false
                        replacement.$textNodeToTranslate.parent().contents(
                        ).each ->
                            if currentDomNodeFound
                                replacement.$currentLanguageDomNode = $ this
                                return false
                            if this is replacement.$textNodeToTranslate[0]
                                currentDomNodeFound = true
                            true
                    currentLanguage = replacement.$currentLanguageDomNode.prop(
                        'textContent')
                    if language is currentLanguage
                        this.warn(
                            "Text node \"#{replacement.textToReplace}\" is " +
                            "marked as \"#{currentLanguage}\" and has same " +
                            'translation language as it already is.')
                    nodeName = replacement.$nodeToReplace.prop(
                        'nodeName'
                    ).toLowerCase()
                    if nodeName is '#comment'
                        replacement.$textNodeToTranslate.after $(
                            "<!--#{currentLanguage}:#{currentText}-->")
                    else
                        replacement.$textNodeToTranslate.after $(
                            "<#{nodeName}>#{currentLanguage}:#{currentText}<" +
                            "/#{nodeName}>"
                        ).hide()
                    replacement.$textNodeToTranslate.after(
                        $ "<!--#{language}-->")
                    if replacement.$textNodeToTranslate.prop(
                        'nodeName'
                    ) is '#text'
                        replacement.$textNodeToTranslate.prop(
                            'textContent', replacement.textToReplace)
                    else
                        replacement.$textNodeToTranslate.html(
                            replacement.textToReplace)
                    replacement.$currentLanguageDomNode.remove()
                    replacement.$nodeToReplace.remove()
            # Translate registered known text nodes.
            $.each this._textNodesWithKnownLanguage, (key, value) ->
                $.each value, (subKey, value) -> value.prop 'textContent', key
            if window.localStorage?
                window.localStorage.setItem(
                    this._options.sessionDescription, language)
            this.currentLanguage = language
            this
        _switchCurrentLanguageIndicator: (language) ->
            ###
                Switches the current language indicator in language switch
                triggered dom nodes.

                **language {String}** - The new language to switch to.

                **returns {$.Lang}**  - Returns the current instance.
            ###
            $(
                "a[href=\"##{this._options.languageHashPrefix}" +
                "#{this.currentLanguage}\"]." +
                this._options.currentLanguageIndicatorClassName
            ).removeClass this._options.currentLanguageIndicatorClassName
            $(
                "a[href=\"##{this._options.languageHashPrefix}#{language}\"]"
            ).addClass this._options.currentLanguageIndicatorClassName
            this

    # endregion

    # region handle $ extending

    $.Lang = -> $.Tools().controller Lang, arguments
    $.Lang.class = Lang

    # endregion

# endregion

# region dependencies

if this.require?
    this.require.scopeIndicator = 'jQuery.Lang'
    this.require [['jQuery.Tools', 'jquery-tools-1.0.coffee']], main
else
    main this.jQuery

# endregion

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion

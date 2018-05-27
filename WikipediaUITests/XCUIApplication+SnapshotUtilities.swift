import XCTest

// This this uitest target sleeps - the app target this test target taps doesn't.
// This delay just give everything an extra moment to settle.
let oneSecond: UInt32 = 1
let pressDuration = 0.1 // don't set this to too large a value or presses which happen to land on buttons will activate the button instead of letting the drag event bubble up

extension XCUIElement {
    func wmf_tap() -> Bool {
        sleep(oneSecond)
        guard exists else { return false }
        tap()
        sleep(oneSecond)
        return true
    }
}

extension XCUIElementQuery {
    func wmf_firstMatching(key: String) -> XCUIElement {
        sleep(oneSecond)
        // Used `element:boundBy:0` rather than `firstMatch` because the latter doesn't play nice with `exists` checking.
        return matching(NSPredicate(format: "label == %@", key)).element(boundBy: 0)
    }
}

extension XCUIApplication {
    
    // Quick way to get button which works with non-EN langs too (vs. recording which only works for language recorded in)
    func wmf_button(key: String) -> XCUIElement {
        sleep(oneSecond)
        return buttons.wmf_firstMatching(key: wmf_localizedString(key: key))
    }
    
    func wmf_searchField(key: String) -> XCUIElement {
        sleep(oneSecond)
        return searchFields.matching(NSPredicate(format:"placeholderValue == %@", wmf_localizedString(key: key))).element(boundBy: 0)
    }
    
    func wmf_staticText(key: String) -> XCUIElement {
        sleep(oneSecond)
        return staticTexts.wmf_firstMatching(key: wmf_localizedString(key: key))
    }

    // Quick way to tap button which works with non-EN langs too
    func wmf_tapButton(key: String) -> Bool {
        return wmf_button(key: key).wmf_tap()
    }
    
    func wmf_tapStaticText(key: String) -> Bool {
        return wmf_staticText(key: key).wmf_tap()
    }

    func wmf_tapStaticTextStartingWith(key: String) -> Bool {
        return wmf_elementStartingWith(key: key, from: staticTexts).wmf_tap()
    }

    func wmf_tapUnlocalizedCloseButton() -> Bool {
        return buttons.wmf_firstMatching(key: wmf_localizedString(key: "close")).wmf_tap()
    }
    
    func wmf_tapNavigationBarBackButton() -> Bool {
        let backButtonTapped = wmf_tapButton(key: "back")
        guard backButtonTapped else {
            sleep(oneSecond)
            // Needed because if the title is long, the back button sometimes won't have text, as seen on https://stackoverflow.com/q/38595242/135557
            return navigationBars.buttons.element(boundBy: 0).wmf_tap()
        }
        return backButtonTapped
    }
    
    func wmf_tapFirstCollectionViewCell() -> Bool {
        sleep(oneSecond)
        return collectionViews.children(matching: .cell).element(boundBy: 0).wmf_tap()
    }
    
    func wmf_scrollToTop() -> Bool {
        sleep(oneSecond)
        let result = statusBars.element(boundBy: 0).wmf_tap()
        sleep(oneSecond)
        return result
    }
    
    func wmf_scrollElementToTop(element: XCUIElement) {
        let elementTopCoord = element.coordinate(withNormalizedOffset:CGVector(dx: 0.5, dy: 0.0))
        elementTopCoord.press(forDuration: pressDuration, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)))
    }
    
    func wmf_elementStartingWith(key: String, from elementQuery: XCUIElementQuery) -> XCUIElement {
        sleep(oneSecond)

        var translation = wmf_localizedString(key: key)
        
        // HACK: if there's a substitution string - ie "%1$@" - just ignore everything after it (including it) so the BEGINSWITH logic works without us having to get the actual substition value.
        if let rangeOfSubstitutionString = translation.range(of: "%1$@") {
            translation = String(translation[..<rangeOfSubstitutionString.lowerBound])
        }
        
        return elementQuery.matching(NSPredicate(format: "label BEGINSWITH %@", translation)).element(boundBy: 0)
    }
    
    func wmf_scrollDown() {
        let iPadSafeBottomDragStartY: Double = 0.8 // If set to 1.0 it drags from very bottom of the screen which triggers an iPad task switcher and zooms out the app. So drag from a little above the very bottom.
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: iPadSafeBottomDragStartY)).press(forDuration: pressDuration, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -1.0)))
    }
    
    func wmf_scrollToOtherElementStartingWith(key: String, success: (XCUIElement) -> ()){
        let maxScrollSeconds: Double = 240
        let start = Date()
        repeat {
            let element = wmf_elementStartingWith(key: key, from: otherElements)
            if element.exists {
                wmf_scrollElementToTop(element: element)
                sleep(1)
                success(element)
                break
            }
            wmf_scrollDown()
        } while Date().timeIntervalSince(start) < maxScrollSeconds
    }
    
    // Gets localized string from localized string key (so we can navigate the app regardless of lang).
    // ( localization strings are copied into this scheme during a build phase: https://stackoverflow.com/a/38133902/135557 )
    // there's surely a cleaner way to get this path than using all the re-tries below (perhaps using the localization methods in WMF framework?), but this works for the langs we're testing at the moment
    func wmf_localizedString(key: String) -> String {
        let bundle = Bundle(for: WikipediaUITests.self)
        
        // try first with deviceLanguage as-is - i.e. "en-US"
        var bundlePath = bundle.path(forResource:deviceLanguage, ofType: "lproj")
        
        // if no bundlePath try lower case (fixes Chinese)
        if bundlePath == nil {
            bundlePath = bundle.path(forResource:deviceLanguage.lowercased(), ofType: "lproj")
        }
        
        // if no bundlePath try with just the "en" part of "en-US"
        if bundlePath == nil {
            let lang = deviceLanguage.split(separator: "-").first // gets "en" from "en-US", for example
            if lang == nil {
                return ""
            }
            bundlePath = bundle.path(forResource:String(lang!), ofType: "lproj")
        }
        
        if bundlePath == nil {
            return ""
        }
        guard let localizationBundle = Bundle(path: bundlePath!) else {
            return ""
        }
        
        var translation = NSLocalizedString(key, bundle: localizationBundle, comment: "")
        
        if (translation == key || (translation.count == 0)) {
            let enBundlePath = bundle.path(forResource: "en", ofType: "lproj")
            translation = NSLocalizedString(key, bundle: Bundle(path: enBundlePath!)!, comment: "")
        }
        return translation
    }
}

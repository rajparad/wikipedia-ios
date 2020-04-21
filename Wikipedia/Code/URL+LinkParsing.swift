import Foundation

extension URL {
    /// Returns a new URL with the existing scheme replaced with the wikipedia:// scheme
    public var replacingSchemeWithWikipediaScheme: URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = "wikipedia"
        return components?.url
    }
    
    /// Returns the percent encoded page title to handle titles with / characters
    public var percentEncodedPageTitleForPathComponents: String? {
        return wmf_title?.percentEncodedPageTitleForPathComponents
    }
    
    /// Encodes the page title to handle titles with forward slash characters when splitting path components.
    /// The callee should be a standardized page URL generated with wmf_databaseURL, non-article namespaces are OK
    /// For example, https://en.wikipedia.org/wiki/G/O_Media becomes https://en.wikipedia.org/wiki/G%2FO_Media
    public var encodedWikiURL: URL? {
        guard let percentEncodedTitle = percentEncodedPageTitleForPathComponents else {
            assert(false, "encodedWikiURL potentially called on a non-wiki URL")
            return nil
        }
        let encodedPathComponents = ["wiki", percentEncodedTitle]
        var encodedURLComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        encodedURLComponents?.replacePercentEncodedPathWithPathComponents(encodedPathComponents)
        return encodedURLComponents?.url
    }
    
    /// Resolves a relative href from a wiki page against the callee.
    /// The callee should be a standardized page URL generated with wmf_databaseURL, non-article namespaces are OK
    public func resolvingRelativeWikiHref(_ href: String) -> URL? {
        let urlComponentsString: String
        if href.hasPrefix(".") || href.hasPrefix("/") {
            urlComponentsString = href.addingPercentEncoding(withAllowedCharacters: .relativePathAndFragmentAllowed) ?? href
        } else {
            urlComponentsString = href
        }
        let components = URLComponents(string: urlComponentsString)
        // Encode this URL to handle titles with forward slashes, otherwise URLComponents thinks they're separate path components
        let encodedBaseURL = encodedWikiURL
        return components?.url(relativeTo: encodedBaseURL)?.absoluteURL
    }
    
    public var wmf_language: String? {
        return (self as NSURL).wmf_language
    }
    
    public var wmf_title: String? {
        return (self as NSURL).wmf_title
    }
    
    public var wmf_titleWithUnderscores: String? {
        return (self as NSURL).wmf_titleWithUnderscores
    }
    
    public var wmf_databaseKey: String? {
        return (self as NSURL).wmf_databaseKey
    }
    
    public var wmf_site: URL? {
        return (self as NSURL).wmf_site
    }
    
    public func wmf_URL(withTitle title: String) -> URL? {
        return (self as NSURL).wmf_URL(withTitle: title)
    }
    
    public func wmf_URL(withFragment fragment: String) -> URL? {
        return (self as NSURL).wmf_URL(withFragment: fragment)
    }
    
    public func wmf_URL(withPath path: String, isMobile: Bool) -> URL? {
        return (self as NSURL).wmf_URL(withPath: path, isMobile: isMobile)
    }
    
    public var wmf_isNonStandardURL: Bool {
        return (self as NSURL).wmf_isNonStandardURL
    }

    public var wmf_wiki: String? {
        return wmf_language?.replacingOccurrences(of: "-", with: "_").appending("wiki")
    }
    
    fileprivate func wmf_URLForSharing(with wprov: String) -> URL {
        let queryItems = [URLQueryItem(name: "wprov", value: wprov)]
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url ?? self
    }
    
    // URL for sharing text only
    public var wmf_URLForTextSharing: URL {
        return wmf_URLForSharing(with: "sfti1")
    }
    
    // URL for sharing that includes an image (for example, Share-a-fact)
    public var wmf_URLForImageSharing: URL {
        return wmf_URLForSharing(with: "sfii1")
    }
    
    public var canonical: URL {
        return (self as NSURL).wmf_canonical ?? self
    }
    
    public var wikiResourcePath: String? {
        return path.wikiResourcePath
    }
    
    public var wResourcePath: String? {
        return path.wResourcePath
    }
    
    public var namespace: PageNamespace? {
        guard let language = wmf_language else {
            return nil
        }
        return wikiResourcePath?.namespaceOfWikiResourcePath(with: language)
    }
    
    public var namespaceAndTitle: (namespace: PageNamespace, title: String)? {
        guard let language = wmf_language else {
            return nil
        }
        return wikiResourcePath?.namespaceAndTitleOfWikiResourcePath(with: language)
    }
    
    public var articleTalkPage: URL? {
        guard
            let namespaceAndTitle = namespaceAndTitle,
            namespaceAndTitle.namespace == .main
        else {
            return nil
        }
        return wmf_URL(withTitle: "Talk:\(namespaceAndTitle.title)")
    }
    
    public var isPreviewable: Bool {
        return (self as NSURL).wmf_isPeekable
    }
    
    private var isHostedFileLink: Bool {
        return host?.lowercased() == Configuration.Domain.uploads
    }
    
    /// Converts incompatible file links to compatible file links. Currently only translates ogg/oga links to m3 links.
    public var byMakingiOSCompatibilityAdjustments: URL {
        guard isHostedFileLink else {
            return self
        }
        
        let lowercasedPathExtension = pathExtension.lowercased()
        
        guard Configuration.File.Extensions.oggAudio.contains(lowercasedPathExtension) else {
            return self
        }
        
        var mutableComponents = pathComponents
        
        guard
            let filename = mutableComponents.last,
            let index = mutableComponents.firstIndex(of: "commons"),
            index < mutableComponents.count - 1
        else {
            return self
        }
        
        mutableComponents.insert("transcoded", at: index + 1)
        
        let mp3Filename = filename.appending(".mp3")
        mutableComponents.append(mp3Filename)

        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        urlComponents?.path = pathComponents.joined(separator: "/")
        return urlComponents?.url ?? self
    }
}



@objc extension NSURL {
    /// deprecated - use namespace methods
    @objc var wmf_isWikiResource: Bool {
        return (self as URL).wikiResourcePath != nil
    }
}

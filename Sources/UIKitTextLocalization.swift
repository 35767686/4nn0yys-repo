import UIKit
import ObjectiveC.runtime

/// Applies the active language to UIKit text controls throughout the app.
/// Unknown content (song names, artists, usernames, lyrics and server-provided titles) is left untouched.
enum UIKitTextLocalization {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true

        exchange(UILabel.self, #selector(setter: UILabel.text), #selector(UILabel.mochy_setText(_:)))
        exchange(UILabel.self, #selector(setter: UILabel.attributedText), #selector(UILabel.mochy_setAttributedText(_:)))
        exchange(UIButton.self, #selector(UIButton.setTitle(_:for:)), #selector(UIButton.mochy_setTitle(_:for:)))
        exchange(UIButton.self, #selector(UIButton.setAttributedTitle(_:for:)), #selector(UIButton.mochy_setAttributedTitle(_:for:)))
        exchange(UITextField.self, #selector(setter: UITextField.placeholder), #selector(UITextField.mochy_setPlaceholder(_:)))
        exchange(UITextField.self, #selector(setter: UITextField.attributedPlaceholder), #selector(UITextField.mochy_setAttributedPlaceholder(_:)))
        exchange(UISearchBar.self, #selector(setter: UISearchBar.placeholder), #selector(UISearchBar.mochy_setPlaceholder(_:)))
        exchange(UITextView.self, #selector(setter: UITextView.text), #selector(UITextView.mochy_setText(_:)))
        exchange(UITextView.self, #selector(setter: UITextView.attributedText), #selector(UITextView.mochy_setAttributedText(_:)))
        exchange(UIBarButtonItem.self, #selector(setter: UIBarButtonItem.title), #selector(UIBarButtonItem.mochy_setTitle(_:)))
        exchange(UIViewController.self, #selector(setter: UIViewController.title), #selector(UIViewController.mochy_setTitle(_:)))
        exchange(UIView.self, NSSelectorFromString("setAccessibilityLabel:"), #selector(UIView.mochy_setAccessibilityLabel(_:)))
        exchange(UIView.self, NSSelectorFromString("setAccessibilityHint:"), #selector(UIView.mochy_setAccessibilityHint(_:)))
        exchange(UITabBarItem.self, #selector(setter: UITabBarItem.title), #selector(UITabBarItem.mochy_setTitle(_:)))
        exchange(UISegmentedControl.self, #selector(UISegmentedControl.setTitle(_:forSegmentAt:)), #selector(UISegmentedControl.mochy_setTitle(_:forSegmentAt:)))
    }

    private static func exchange(_ type: AnyClass, _ original: Selector, _ replacement: Selector) {
        guard let originalMethod = class_getInstanceMethod(type, original),
              let replacementMethod = class_getInstanceMethod(type, replacement) else { return }
        method_exchangeImplementations(originalMethod, replacementMethod)
    }

    static func localized(_ source: NSAttributedString?) -> NSAttributedString? {
        guard let source = source, source.length > 0 else { return source }
        let translated = AppLocalization.text(source.string)
        guard translated != source.string else { return source }
        var attributes: [NSAttributedString.Key: Any] = [:]
        if source.length > 0 {
            attributes = source.attributes(at: 0, effectiveRange: nil)
        }
        return NSAttributedString(string: translated, attributes: attributes)
    }
}

private extension UILabel {
    @objc dynamic func mochy_setText(_ value: String?) {
        mochy_setText(value.map { AppLocalization.text($0) })
    }

    @objc dynamic func mochy_setAttributedText(_ value: NSAttributedString?) {
        mochy_setAttributedText(UIKitTextLocalization.localized(value))
    }
}

private extension UIButton {
    @objc dynamic func mochy_setTitle(_ title: String?, for state: UIControl.State) {
        mochy_setTitle(title.map { AppLocalization.text($0) }, for: state)
    }

    @objc dynamic func mochy_setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
        mochy_setAttributedTitle(UIKitTextLocalization.localized(title), for: state)
    }
}

private extension UITextField {
    @objc dynamic func mochy_setPlaceholder(_ value: String?) {
        mochy_setPlaceholder(value.map { AppLocalization.text($0) })
    }

    @objc dynamic func mochy_setAttributedPlaceholder(_ value: NSAttributedString?) {
        mochy_setAttributedPlaceholder(UIKitTextLocalization.localized(value))
    }
}

private extension UISearchBar {
    @objc dynamic func mochy_setPlaceholder(_ value: String?) {
        mochy_setPlaceholder(value.map { AppLocalization.text($0) })
    }
}

private extension UITextView {
    @objc dynamic func mochy_setText(_ value: String?) {
        mochy_setText(value.map { AppLocalization.text($0) })
    }

    @objc dynamic func mochy_setAttributedText(_ value: NSAttributedString?) {
        mochy_setAttributedText(UIKitTextLocalization.localized(value))
    }
}

private extension UIBarButtonItem {
    @objc dynamic func mochy_setTitle(_ value: String?) {
        mochy_setTitle(value.map { AppLocalization.text($0) })
    }
}

private extension UIViewController {
    @objc dynamic func mochy_setTitle(_ value: String?) {
        // These screens display server-provided artist/album names as their navigation title.
        // Keep metadata untouched; their actual interface controls are localized separately.
        if self is UIAlertController || self is ArtistViewController || self is MusicPageViewController {
            // Alert factories and metadata pages decide explicitly whether titles are UI or user content.
            mochy_setTitle(value)
        } else {
            mochy_setTitle(value.map { AppLocalization.text($0) })
        }
    }
}

private extension UITabBarItem {
    @objc dynamic func mochy_setTitle(_ value: String?) {
        mochy_setTitle(value.map { AppLocalization.text($0) })
    }
}

private extension UISegmentedControl {
    @objc dynamic func mochy_setTitle(_ title: String?, forSegmentAt segment: Int) {
        mochy_setTitle(title.map { AppLocalization.text($0) }, forSegmentAt: segment)
    }
}

private extension UIView {
    @objc dynamic func mochy_setAccessibilityLabel(_ value: String?) {
        mochy_setAccessibilityLabel(value.map { AppLocalization.text($0) })
    }

    @objc dynamic func mochy_setAccessibilityHint(_ value: String?) {
        mochy_setAccessibilityHint(value.map { AppLocalization.text($0) })
    }
}

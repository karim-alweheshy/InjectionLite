
import Foundation

func topLevelValue() -> String {
    return "VALUE26050"
}

struct TestStruct {
    let c1 = GenericSuper(t: 77)
    let c2 = GenericSuper(t: 88.5)
    let c3 = GenericSuper(t: "__")
    static func staticValue() -> String {
        return "VALUE26050"
    }
    func value() -> String {
        return "VALUE26050"
    }
}

class TestSuper<T> {
    func fileOnePath() -> String {
        return #filePath
    }
    static func staticBaseValue() -> String {
        return "VALUE26050"
    }
    class func classBaseValue() -> String {
        return "VALUE26050"
    }
    func baseValue() -> String {
        return "VALUE26050"
    }
}

class GenericSuper<T>: TestSuper<T> {
    var t: T
    init(t: T) {
        self.t = t
    }
    static func staticValue() -> String {
        return "VALUE26050"
    }
    class func classSuperValue() -> String {
        return "VALUE26050"
    }
    func superValue() -> String {
        return "VALUE26050"
    }

    @objc func injected() {
        InjectionLiteTests.checks.remove("VALUE26050-\(t)")
    }
}

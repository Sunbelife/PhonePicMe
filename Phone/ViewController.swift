import UIKit
import AddressBook
import AddressBookUI


extension String {
    
    func upcaseInitial() -> String {
        var chars = characters
        if let firstChar = chars.popFirst().map({ String($0) }) {
            return String(firstChar).uppercased() + String(chars)
        }
        return ""
    }
    
    func phonetic() -> String {
        let src = NSMutableString(string: self) as CFMutableString
        CFStringTransform(src, nil, kCFStringTransformMandarinLatin, false)
        
        // Transform NínHǎo to NinHao
        CFStringTransform(src, nil, kCFStringTransformStripCombiningMarks, false)
        
        let s = src as String
        if s != self {
            return s
                .components(separatedBy: " ")
                .map { $0.upcaseInitial() }
                .reduce("", +)
        }
        
        return self
    }
    func phoneticLast() -> String {
        let SpecialLastName: [String: String] = [
            "柏": "bai",
            "鲍": "bao",
            "贲": "ben",
            "秘": "bi",
            "薄": "bo",
            "卜": "bu",
            "岑": "cen",
            "晁": "chao",
            "谌": "chen",
            "种": "chong",
            "褚": "chu",
            "啜": "chuai",
            "单": "chan",
            "郗": "chi",
            "邸": "di",
            "都": "du",
            "缪": "miao",
            "宓": "mi",
            "费": "fei",
            "苻": "fu",
            "睢": "sui",
            "区": "ou",
            "华": "hua",
            "庞": "pang",
            "查": "zha",
            "佘": "she",
            "仇": "qiu",
            "靳": "jin",
            "解": "xie",
            "繁": "po",
            "折": "she",
            "员": "yun",
            "祭": "zhai",
            "芮": "rui",
            "覃": "tan",
            "牟": "mou",
            "蕃": "pi",
            "戚": "qi",
            "瞿": "qu",
            "冼": "xian",
            "洗": "xian",
            "郤": "xi",
            "庹": "tuo",
            "彤": "tong",
            "佟": "tong",
            "妫": "gui",
            "句": "gou",
            "郝": "hao",
            "曾": "zeng",
            "乐": "yue",
            "蔺": "lin",
            "隽": "juan",
            "臧": "zang",
            "庾": "yu",
            "詹": "zhan",
            "禚": "zhuo",
            "迮": "ze",
            "沈": "shen",
            "沉": "shen",
            "尉迟": "yuchi",
            "长孙": "zhangsun",
            "中行": "zhonghang",
            "万俟": "moqi",
            "单于": "chanyu"
        ]
        
        if let specialLastName = SpecialLastName[self] {
            return specialLastName.upcaseInitial()
        }
        return self
    }
}

class ViewController: UIViewController {
    // address Book对象，用来获取电话簿句柄
    var addressBook:ABAddressBook?
    
    @IBAction func addPhonePic() {
        
        // 定义一个错误标记对象，判断是否成功
        var error:Unmanaged<CFError>?
        
        addressBook = ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
        
        // 发出授权信息
        let sysAddressBookStatus = ABAddressBookGetAuthorizationStatus()
        if (sysAddressBookStatus == ABAuthorizationStatus.notDetermined) {
            print("requesting access...")
            var errorRef:Unmanaged<CFError>? = nil
            // addressBook = extractABAddressBookRef(ABAddressBookCreateWithOptions(nil, &errorRef))
            ABAddressBookRequestAccessWithCompletion(addressBook, { success, error in
                if success {
                    // 获取并遍历所有联系人记录
                    self.readRecords();
                }
                else {
                    print("error")
                }
            })
        }
        else if (sysAddressBookStatus == ABAuthorizationStatus.denied ||
            sysAddressBookStatus == ABAuthorizationStatus.restricted) {
            print("access denied")
        }
        else if (sysAddressBookStatus == ABAuthorizationStatus.authorized) {
            print("access granted")
            // 获取并遍历所有联系人记录
            self.readRecords();
        }
    }
    
    // 获取并遍历所有联系人记录
    func readRecords(){
        var error:Unmanaged<CFError>?
        var p:Double
        var loop:Int = 0
        var sysContacts:NSArray = ABAddressBookCopyArrayOfAllPeople(addressBook)
            .takeRetainedValue() as NSArray
        
        for contact in sysContacts {
            loop += 1
            let p = loop*100/sysContacts.count
            print("进度：" + (String)(p) + "%")
            
            // 获取姓
            var lastName = ABRecordCopyValue(contact as ABRecord!, kABPersonLastNameProperty)?
                .takeRetainedValue() as! String? ?? ""
            lastName = lastName.phoneticLast().phonetic()
            ABRecordSetValue (contact as ABRecord!, kABPersonLastNamePhoneticProperty,lastName as CFTypeRef!, &error)
            
            // 获取名
            var firstName = ABRecordCopyValue(contact as ABRecord!, kABPersonFirstNameProperty)?
                .takeRetainedValue() as! String? ?? ""
            firstName = firstName.phoneticLast().phonetic()
            
            ABRecordSetValue (contact as ABRecord!, kABPersonFirstNamePhoneticProperty,firstName as CFTypeRef!, &error)
            ABAddressBookSave(addressBook, &error)
        }
        let showalert = UIAlertView()
        showalert.title = "修改完毕"
        showalert.message = "所有联系人已添加拼音，您现在可以切换到英文系统了，虽然有点感伤，但是您现在可以删了本 App，再见。"
        showalert.addButton(withTitle: "好的")
        showalert.show()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

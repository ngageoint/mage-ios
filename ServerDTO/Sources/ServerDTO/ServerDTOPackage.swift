import os
import Foundation

public enum ServerDTOPackage {
    static let logger = Logger(subsystem: "ServerDTO", category: "ServerDTO")
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        return formatter;
    }()
}

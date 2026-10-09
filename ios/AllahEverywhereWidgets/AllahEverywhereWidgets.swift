import SwiftUI
import WidgetKit

// Home and Lock Screen widgets: Next Prayer, Islamic (Hijri) Date and Verse
// of the Day. The app computes everything in its own language for days ahead
// (lib/services/home_widget_service.dart) and shares it through the App
// Group; the widgets only pick today's entry, so they work offline and keep
// going even if the app isn't opened for a while.

private let appGroup = "group.com.allaheverywhere.app"

// MARK: - Shared data

struct WidgetPayload: Decodable {
  struct Prayer: Decodable {
    let id: String
    let n: String
    let t: Double  // epoch milliseconds
    let s: String
    var date: Date { Date(timeIntervalSince1970: t / 1000) }
  }

  struct PrayerDay: Decodable {
    let day: String
    let items: [Prayer]
  }

  struct HijriDay: Decodable {
    let day: String
    let h: String
    let d: String
    let m: String
    let y: String
    let g: String
    let e: String
  }

  struct Reminder: Decodable {
    let day: String
    let title: String
    let ar: String
    let tr: String
    let ref: String
  }

  let lang: String
  let rtl: Bool
  let labels: [String: String]
  let prayers: [PrayerDay]
  let hijri: [HijriDay]
  let reminders: [Reminder]

  static func load() -> WidgetPayload? {
    guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: "widget_data"),
      let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(WidgetPayload.self, from: data)
  }

  static func dayKey(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
  }

  func label(_ key: String) -> String? { labels[key].flatMap { $0.isEmpty ? nil : $0 } }

  /// Every saved prayer after [date], in time order.
  func upcoming(after date: Date) -> [Prayer] {
    prayers.flatMap { $0.items }.filter { $0.date > date }.sorted { $0.t < $1.t }
  }

  func prayers(on date: Date) -> [Prayer] {
    prayers.first { $0.day == Self.dayKey(date) }?.items ?? []
  }

  func hijri(on date: Date) -> HijriDay? { hijri.first { $0.day == Self.dayKey(date) } }

  func reminder(on date: Date) -> Reminder? { reminders.first { $0.day == Self.dayKey(date) } }

  var direction: LayoutDirection { rtl ? .rightToLeft : .leftToRight }
}

// MARK: - Look

private extension Color {
  static func dynamic(light: UInt32, dark: UInt32) -> Color {
    func ui(_ hex: UInt32) -> UIColor {
      UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
    return Color(UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
  }

  // The app's palette (lib/utils/utils/constraints/colors.dart).
  static let widgetBackground = dynamic(light: 0xFBF6EE, dark: 0x211F17)
  static let widgetText = dynamic(light: 0x4B4B32, dark: 0xF3EEE4)
  static let widgetSecondary = dynamic(light: 0x6C7570, dark: 0xB9B3A4)
  static let widgetAccent = dynamic(light: 0xB0832C, dark: 0xE8C165)
}

/// Amiri ships with the extension for Arabic text; falls back to the system.
private func arabicFont(_ size: CGFloat) -> Font {
  UIFont(name: "Amiri-Regular", size: size) != nil ? .custom("Amiri-Regular", size: size) : .system(size: size)
}

private extension View {
  /// iOS 17 needs the background declared as the widget's container.
  @ViewBuilder func widgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { Color.widgetBackground }
    } else {
      background(Color.widgetBackground)
    }
  }
}

private func link(_ route: String) -> URL? { URL(string: "allaheverywhere://\(route)?homeWidget") }

// MARK: - Next Prayer

struct PrayerEntry: TimelineEntry {
  let date: Date
  let payload: WidgetPayload?
}

struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), payload: nil) }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(PrayerEntry(date: Date(), payload: WidgetPayload.load()))
  }

  /// One entry now and one at each upcoming prayer, so "next" moves on by
  /// itself; the countdown is a live timer text between entries.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let now = Date()
    let payload = WidgetPayload.load()
    var entries = [PrayerEntry(date: now, payload: payload)]
    for prayer in (payload?.upcoming(after: now) ?? []).prefix(30) {
      entries.append(PrayerEntry(date: prayer.date.addingTimeInterval(1), payload: payload))
    }
    let tomorrow = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
    completion(Timeline(entries: entries, policy: .after(entries.count > 1 ? entries.last!.date : tomorrow)))
  }
}

struct NextPrayerView: View {
  @Environment(\.widgetFamily) var family
  let entry: PrayerEntry

  var body: some View {
    let payload = entry.payload
    let next = payload?.upcoming(after: entry.date).first
    let title = payload?.label("next") ?? String(localized: "widget.nextPrayer.fallback")
    Group {
      switch family {
      case .accessoryInline:
        if let next {
          Text("\(next.n) \(next.s)")
        } else {
          Text(title)
        }
      case .accessoryCircular:
        VStack(spacing: 0) {
          Text(next?.n ?? "—").font(.system(size: 11, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.6)
          if let next {
            Text(next.date, style: .timer).font(.system(size: 10)).multilineTextAlignment(.center)
          }
        }
      case .accessoryRectangular:
        VStack(alignment: .leading, spacing: 1) {
          Text(title).font(.caption2).foregroundStyle(.secondary)
          if let next {
            Text("\(next.n) · \(next.s)").font(.headline).lineLimit(1)
            Text(next.date, style: .timer).font(.caption)
          } else {
            Text(payload?.label("setLocation") ?? String(localized: "widget.setLocation.fallback"))
              .font(.caption).lineLimit(2)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      case .systemMedium:
        HStack(spacing: 14) {
          summary(title: title, next: next, payload: payload)
          if let payload, next != nil {
            Rectangle().fill(Color.widgetAccent.opacity(0.3)).frame(width: 1)
            list(payload: payload, next: next)
          }
        }
      default:
        summary(title: title, next: next, payload: payload)
      }
    }
    .environment(\.layoutDirection, payload?.direction ?? .leftToRight)
    .widgetBackground()
    .widgetURL(link("prayer"))
  }

  private func summary(title: String, next: WidgetPayload.Prayer?, payload: WidgetPayload?) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.widgetAccent).lineLimit(1)
      if let next {
        Text(next.n).font(.system(size: 24, weight: .bold)).foregroundColor(.widgetText)
          .lineLimit(1).minimumScaleFactor(0.6)
        Text(next.s).font(.system(size: 14)).foregroundColor(.widgetSecondary)
        Text(next.date, style: .timer).font(.system(size: 18, weight: .bold).monospacedDigit())
          .foregroundColor(.widgetAccent)
      } else {
        Text(payload?.label("setLocation") ?? String(localized: "widget.setLocation.fallback"))
          .font(.system(size: 13)).foregroundColor(.widgetSecondary).lineLimit(3)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func list(payload: WidgetPayload, next: WidgetPayload.Prayer?) -> some View {
    let day = payload.prayers(on: entry.date)
    let items = day.isEmpty ? payload.prayers(on: next?.date ?? entry.date) : day
    return VStack(spacing: 2) {
      ForEach(items, id: \.id) { p in
        let isNext = p.t == next?.t
        HStack {
          Text(p.n).lineLimit(1)
          Spacer(minLength: 4)
          Text(p.s).monospacedDigit()
        }
        .font(.system(size: 13, weight: isNext ? .bold : .regular))
        .foregroundColor(isNext ? .widgetAccent : .widgetText)
        .frame(maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

struct NextPrayerWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "NextPrayerWidget", provider: PrayerProvider()) { entry in
      NextPrayerView(entry: entry)
    }
    .configurationDisplayName(Text("widget.nextPrayer.name"))
    .description(Text("widget.nextPrayer.description"))
    .supportedFamilies(Self.families)
  }

  static var families: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular]
    }
    return [.systemSmall, .systemMedium]
  }
}

// MARK: - Daily entries (Hijri date, Verse of the Day)

struct DayEntry: TimelineEntry {
  let date: Date
  let payload: WidgetPayload?
}

/// One entry per day at midnight for the week ahead.
struct DayProvider: TimelineProvider {
  func placeholder(in context: Context) -> DayEntry { DayEntry(date: Date(), payload: nil) }

  func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
    completion(DayEntry(date: Date(), payload: WidgetPayload.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
    let now = Date()
    let payload = WidgetPayload.load()
    let calendar = Calendar.current
    var entries = [DayEntry(date: now, payload: payload)]
    for offset in 1...7 {
      if let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) {
        entries.append(DayEntry(date: day, payload: payload))
      }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct HijriDateView: View {
  @Environment(\.widgetFamily) var family
  let entry: DayEntry

  var body: some View {
    let day = entry.payload?.hijri(on: entry.date)
    let fallback = entry.payload?.label("openApp") ?? String(localized: "widget.openApp.fallback")
    Group {
      switch family {
      case .accessoryInline:
        Text(day?.h ?? fallback)
      case .accessoryRectangular:
        VStack(alignment: .leading, spacing: 1) {
          Text(day.map { "\($0.d) \($0.m)" } ?? fallback).font(.headline).lineLimit(1)
          Text(day?.y ?? "").font(.caption)
          if let e = day?.e, !e.isEmpty { Text(e).font(.caption2).lineLimit(1) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      default:
        VStack(spacing: 2) {
          if let day {
            Text(day.d).font(.system(size: 40, weight: .bold)).foregroundColor(.widgetAccent)
            Text(day.m).font(.system(size: 15, weight: .bold)).foregroundColor(.widgetText)
              .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
            Text(day.y).font(.system(size: 12)).foregroundColor(.widgetSecondary)
            Text(day.g).font(.system(size: 11)).foregroundColor(.widgetSecondary).lineLimit(1)
              .minimumScaleFactor(0.7).padding(.top, 2)
            if !day.e.isEmpty {
              Text(day.e).font(.system(size: 11, weight: .bold)).foregroundColor(.widgetAccent)
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7).padding(.top, 2)
            }
          } else {
            Text(fallback).font(.system(size: 13)).foregroundColor(.widgetSecondary).multilineTextAlignment(.center)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .environment(\.layoutDirection, entry.payload?.direction ?? .leftToRight)
    .widgetBackground()
    .widgetURL(link("calendar"))
  }
}

struct HijriDateWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "HijriDateWidget", provider: DayProvider()) { entry in
      HijriDateView(entry: entry)
    }
    .configurationDisplayName(Text("widget.hijriDate.name"))
    .description(Text("widget.hijriDate.description"))
    .supportedFamilies(Self.families)
  }

  static var families: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .accessoryRectangular, .accessoryInline]
    }
    return [.systemSmall]
  }
}

struct DailyReminderView: View {
  @Environment(\.widgetFamily) var family
  let entry: DayEntry

  var body: some View {
    let item = entry.payload?.reminder(on: entry.date)
    let large = family == .systemLarge
    VStack(spacing: large ? 10 : 5) {
      Text(item?.title ?? String(localized: "widget.reminder.name"))
        .font(.system(size: 12, weight: .bold)).foregroundColor(.widgetAccent)
        .frame(maxWidth: .infinity, alignment: .leading)
      if let item {
        Text(item.ar).font(arabicFont(large ? 24 : 19)).foregroundColor(.widgetText)
          .multilineTextAlignment(.center).lineLimit(large ? 6 : 2).minimumScaleFactor(0.7)
          .environment(\.layoutDirection, .rightToLeft)
        Text(item.tr).font(.system(size: large ? 15 : 13)).foregroundColor(.widgetText)
          .multilineTextAlignment(.center).lineLimit(large ? 8 : 3).minimumScaleFactor(0.8)
        Text(item.ref).font(.system(size: 11)).foregroundColor(.widgetSecondary).lineLimit(1)
      } else {
        Text(entry.payload?.label("openApp") ?? String(localized: "widget.openApp.fallback"))
          .font(.system(size: 13)).foregroundColor(.widgetSecondary)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .environment(\.layoutDirection, entry.payload?.direction ?? .leftToRight)
    .widgetBackground()
    .widgetURL(link("home"))
  }
}

struct DailyReminderWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DailyReminderWidget", provider: DayProvider()) { entry in
      DailyReminderView(entry: entry)
    }
    .configurationDisplayName(Text("widget.reminder.name"))
    .description(Text("widget.reminder.description"))
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

@main
struct AllahEverywhereWidgets: WidgetBundle {
  var body: some Widget {
    NextPrayerWidget()
    HijriDateWidget()
    DailyReminderWidget()
  }
}

import Foundation

// MARK: - Parallel Lives — Legendary timelines for motivation

struct LegendStory: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let timeframe: TimeHorizon
    let achievement: String
    let quote: String
    let region: Region // .india, .global, .usa

    enum Region { case india, usa, global }
}

// MARK: - Content Library

enum ParallelLives {
    static let all: [LegendStory] = [
        // ── 6 MONTHS ──
        LegendStory(name: "Colonel Sanders", emoji: "🍗", timeframe: .sixMonths,
                    achievement: "Was rejected 1,009 times before a restaurant finally accepted his fried chicken recipe at age 65.",
                    quote: "\"I made a resolve then that I was going to amount to something if I could. And no hours, nor amount of labor, nor amount of money would deter me.\"",
                    region: .global),

        LegendStory(name: "Sushant Singh Rajput", emoji: "🎬", timeframe: .sixMonths,
                    achievement: "Dropped out of DTU engineering, moved to Mumbai with only ₹5,000, and got his first TV role in 'Kis Desh Mein Hai Meraa Dil' within 6 months.",
                    quote: "\"I come from a small town. I had no Godfather in the industry. If I can do it, anyone can.\"",
                    region: .india),

        LegendStory(name: "Sara Blakely", emoji: "👖", timeframe: .sixMonths,
                    achievement: "Went from selling fax machines door-to-door to prototyping Spanx in her apartment. Got into Neiman Marcus in 6 months. Became the youngest self-made female billionaire.",
                    quote: "\"Don't be intimidated by what you don't know. That can be your greatest strength.\"",
                    region: .global),

        // ── 1 YEAR ──
        LegendStory(name: "J.K. Rowling", emoji: "📚", timeframe: .oneYear,
                    achievement: "Went from suicidal single mother on welfare to published author. Harry Potter was rejected by 12 publishers in one year before Bloomsbury took a chance.",
                    quote: "\"Rock bottom became the solid foundation on which I rebuilt my life.\"",
                    region: .global),

        LegendStory(name: "Virat Kohli", emoji: "🏏", timeframe: .oneYear,
                    achievement: "After losing his father at 18, went from Delhi U-19 captain to India U-19 World Cup winning captain in one year. Scored 90 against Karnataka the day after his father's funeral.",
                    quote: "\"I like to live each moment as it comes. Whatever the situation is, I try to give my best.\"",
                    region: .india),

        LegendStory(name: "Howard Schultz", emoji: "☕", timeframe: .oneYear,
                    achievement: "Visited Italy, fell in love with espresso culture, and convinced Starbucks to pivot from bean retailer to coffeehouse chain. Within a year, the first Starbucks café opened.",
                    quote: "\"In times of adversity and change, we really discover who we are.\"",
                    region: .global),

        // ── 3 YEARS ──
        LegendStory(name: "Sushant Singh Rajput", emoji: "🌟", timeframe: .threeYears,
                    achievement: "Transformed from TV actor to Bollywood leading man in 3 years. Delivered Kai Po Che, Shuddh Desi Romance, Detective Byomkesh Bakshy, and MS Dhoni biopic — all critically acclaimed.",
                    quote: "\"The MS Dhoni biopic took everything from me. I lived like him for 13 months. When you commit fully, the universe conspires.\"",
                    region: .india),

        LegendStory(name: "Steve Jobs", emoji: "🍎", timeframe: .threeYears,
                    achievement: "Went from being fired by Apple's board to founding NeXT and buying Pixar for $10M. Within 3 years, Pixar released Toy Story and Jobs returned to Apple.",
                    quote: "\"The heaviness of being successful was replaced by the lightness of being a beginner again.\"",
                    region: .usa),

        LegendStory(name: "Priyanka Chopra", emoji: "👑", timeframe: .threeYears,
                    achievement: "Went from Miss World pageant winner to Bollywood outsider to landing a lead role in an American network TV show (Quantico). First South Asian to headline a US drama series.",
                    quote: "\"I don't believe in plan B. If I have plan A and I put my 100% into it, I don't need a plan B.\"",
                    region: .india),

        // ── 5 YEARS ──
        LegendStory(name: "Elon Musk", emoji: "🚀", timeframe: .fiveYears,
                    achievement: "Turned PayPal exit money into SpaceX and Tesla. Within 5 years, went from 3 consecutive Falcon 1 failures to NASA contract and Tesla IPO. Both companies nearly bankrupted him.",
                    quote: "\"When something is important enough, you do it even if the odds are not in your favor.\"",
                    region: .global),

        LegendStory(name: "Dr. A.P.J. Abdul Kalam", emoji: "🇮🇳", timeframe: .fiveYears,
                    achievement: "Led India's SLV-3 project from failure to putting the Rohini satellite in orbit — establishing India as a space power. Went from newspaper delivery boy to Missile Man of India.",
                    quote: "\"Dreams are not those which come while we are sleeping, but dreams are those when you don't sleep before fulfilling them.\"",
                    region: .india),

        LegendStory(name: "Oprah Winfrey", emoji: "📺", timeframe: .fiveYears,
                    achievement: "Transformed a struggling local Chicago talk show into the #1 daytime talk show in America. Within 5 years, she launched Harpo Studios and became the richest African American of the 20th century.",
                    quote: "\"The biggest adventure you can ever take is to live the life of your dreams.\"",
                    region: .usa),

        // ── 10 YEARS ──
        LegendStory(name: "Nelson Mandela", emoji: "✊", timeframe: .tenYears,
                    achievement: "Spent 27 years in prison, then within 10 years of release became the first Black president of South Africa, dismantled apartheid, and won the Nobel Peace Prize.",
                    quote: "\"It always seems impossible until it's done.\"",
                    region: .global),

        LegendStory(name: "Dhirubhai Ambani", emoji: "🏭", timeframe: .tenYears,
                    achievement: "Started Reliance with ₹15,000 after returning from Yemen. Within 10 years, turned a textile trading post into a publicly listed company, creating India's first equity cult. From petrol pump attendant to industrialist.",
                    quote: "\"If you don't build your own dream, someone else will hire you to help build theirs.\"",
                    region: .india),

        LegendStory(name: "Sara Blakely (decade)", emoji: "💪", timeframe: .tenYears,
                    achievement: "From selling fax machines to youngest self-made female billionaire on Forbes. Took Spanx from prototype to global brand with zero outside funding. Owns 100% of the company.",
                    quote: "\"It's important to be willing to make mistakes. The worst thing that can happen is you become memorable.\"",
                    region: .global),
    ]

    /// Returns stories filtered by horizon and locale preference
    static func forHorizon(_ horizon: TimeHorizon, locale: LegendStory.Region = .global) -> [LegendStory] {
        let filtered = all.filter { $0.timeframe == horizon }
        // Prioritize locale matches, then include global
        let local = filtered.filter { $0.region == locale }
        let global = filtered.filter { $0.region == .global && !local.contains(where: { $0.name == $0.name }) }
        return local + global
    }

    /// Returns a random story for a given horizon
    static func random(for horizon: TimeHorizon, locale: LegendStory.Region = .global) -> LegendStory {
        let stories = forHorizon(horizon, locale: locale)
        return stories.randomElement() ?? all[0]
    }

    /// Detects the user's likely locale from device settings
    static var userLocale: LegendStory.Region {
        let regionCode = Locale.current.region?.identifier ?? "US"
        if regionCode == "IN" { return .india }
        if regionCode == "US" { return .usa }
        return .global
    }
}

import Foundation

enum NoteSearch {
    static let resultLimit = 200

    struct Query: Sendable {
        let terms: [String]

        init(_ raw: String) {
            terms = raw.split(whereSeparator: \Character.isWhitespace).map(String.init)
        }

        var isEmpty: Bool { terms.isEmpty }
    }

    static func match(
        query: Query,
        summary: NoteSummary,
        source: String?
    ) -> NoteSearchResult? {
        guard !query.isEmpty else { return nil }

        var titleScore = 0
        var titleMatches = 0
        for term in query.terms {
            if let match = FuzzyMatch.match(query: term, candidate: summary.displayTitle) {
                titleMatches += 1
                titleScore += match.score
                continue
            }
            guard let source,
                source.range(
                    of: term,
                    options: [.caseInsensitive, .diacriticInsensitive]) != nil
            else { return nil }
        }

        let band: Int
        if titleMatches == query.terms.count {
            band = 2_000_000
        } else if titleMatches > 0 {
            band = 1_000_000
        } else {
            band = 0
        }
        return NoteSearchResult(summary: summary, score: band + titleScore)
    }

    /// True when each old term starts a new term, so no note can match `query` without `previous`.
    static func narrows(_ query: String, from previous: String) -> Bool {
        let old = Query(previous).terms
        let new = Query(query).terms
        return !old.isEmpty && old.allSatisfy { term in
            new.contains { $0.hasPrefix(term) && !splitsFold($0, after: term.count) }
        }
    }

    /// Pairs one character folds into, as "ß" matches "ss"; a term cut between them is no prefix.
    private static let foldedPairs: Set<String> = [
        "ss", "ff", "fi", "fl", "st", "ʼn", "aʾ", "αι", "ηι", "ωι", "եւ", "մն", "մե", "մի", "վն", "մխ"
    ]

    private static func splitsFold(_ term: String, after count: Int) -> Bool {
        let characters = Array(term)
        guard count > 0, count < characters.count else { return false }
        let pair = String(characters[count - 1]) + String(characters[count])
        return foldedPairs.contains(
            pair.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil))
    }

    /// Every term in the title outranks any body match, so these rows head the full search's answer.
    static func titleMatches(_ query: Query, in summaries: [NoteSummary]) -> [NoteSearchResult] {
        Array(
            summaries.compactMap { match(query: query, summary: $0, source: nil) }
                .sorted(by: precedes).prefix(resultLimit))
    }

    static func precedes(_ lhs: NoteSearchResult, _ rhs: NoteSearchResult) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        if lhs.summary.modifiedAt != rhs.summary.modifiedAt {
            return lhs.summary.modifiedAt > rhs.summary.modifiedAt
        }
        return lhs.summary.displayTitle.localizedCaseInsensitiveCompare(rhs.summary.displayTitle)
            == .orderedAscending
    }
}

use crate::config::Config;
use fuzzy_matcher::skim::SkimMatcherV2;
use fuzzy_matcher::FuzzyMatcher;

pub fn find_match(cfg: &Config, query: &str) -> Option<String> {
    let matcher = SkimMatcherV2::default();
    cfg.projects
        .iter()
        .max_by_key(|(alias, _)| matcher.fuzzy_match(alias, query))
        .map(|(_, path)| path.clone())
}

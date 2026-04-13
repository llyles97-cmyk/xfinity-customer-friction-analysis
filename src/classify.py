"""
classify.py
-----------
Keyword-based multi-label complaint classifier for Comcast/Xfinity FCC complaint data.

Approach: rule-based keyword matching against lowercased complaint text.
Each complaint can match multiple categories (multi-label); the primary category
is resolved via a priority ordering that reflects typical complaint severity and
distinctiveness in a telecom CX context.

Limitations:
- Keyword overlap is high across categories (e.g., "cancel" triggers both
  contract_dispute and service_change). category_count should be interpreted
  as a rough complexity signal, not a precise multi-label count.
- FCC boilerplate appended to complaints (case notice text, URLs) may trigger
  false positives on certain keywords.
- Priority ordering favors billing_issue, which inflates its share as primary
  category. A trained classifier would produce more balanced results.
"""

from __future__ import annotations
from typing import List

# ---------------------------------------------------------------------------
# Keyword taxonomy
# ---------------------------------------------------------------------------

CATEGORY_KEYWORDS: dict[str, list[str]] = {
    "billing_issue": [
        "charge", "charged", "overcharged", "bill", "billing", "invoice",
        "fee", "fees", "payment", "autopay", "auto pay", "credit card",
        "promotional", "promo", "rate increase", "price increase",
        "unexpected charge", "unauthorized charge", "refund", "credited",
        "past due", "collection", "debt", "owe", "balance",
        "double charge", "duplicate charge", "incorrect bill",
        "took money", "debited", "withdrew", "charged my card",
        "amount taken", "auto charged", "without permission",
    ],
    "contract_dispute": [
        "contract", "agreement", "term", "cancel", "cancellation",
        "early termination", "etf", "termination fee", "lock in",
        "2 year", "1 year", "auto-renew", "renewal", "commitment",
        "no contract", "month to month", "disconnect fee",
        "bait and switch", "locked in price", "price changed",
    ],
    "outage_compensation": [
        "credit for outage", "service credit", "reimburse", "reimbursement",
        "compensate", "compensation", "days without service",
        "outage credit", "prorated", "pro-rate", "refund for",
        "not paying for", "service was out", "hours without",
        "credit me", "won't compensate", "no credit given",
    ],
    "installation_issue": [
        "install", "installation", "technician", "tech visit", "appointment",
        "setup", "activate", "activation", "wiring", "cable run",
        "no show", "missed appointment", "reschedule", "new service",
        "self install", "kit", "coaxial", "splitter",
        "delay", "late", "never showed",
    ],
    "equipment_issue": [
        "modem", "router", "gateway", "box", "xfinity box", "x1",
        "remote", "equipment", "hardware", "device", "rental",
        "equipment fee", "lease", "defective", "broken", "replace",
        "return", "own equipment", "bring your own", "compatible",
        "reset", "reboot", "not responding",
    ],
    "network_issue": [
        "outage", "down", "not working", "no internet", "no service",
        "slow", "speed", "bandwidth", "latency", "ping", "buffering",
        "drops", "disconnecting", "unstable", "signal", "connection",
        "packet loss", "jitter", "throttl", "data cap", "congestion",
        "upload", "download", "mbps", "wifi", "wireless",
        "lag", "streaming", "netflix", "gaming", "zoom", "video call",
    ],
    "service_change": [
        "upgrade", "downgrade", "change plan", "switch plan", "port",
        "number transfer", "porting", "transfer service", "move service",
        "new address", "relocate", "pause service", "suspend",
        "account transfer", "add line", "remove line",
        "cancel service", "stop service", "disconnect service",
    ],
    "customer_service": [
        "agent", "representative", "rep", "supervisor", "manager",
        "hold", "on hold", "wait", "waited", "transfer", "transferred",
        "hung up", "disconnected", "rude", "unprofessional", "disrespectful",
        "no response", "no call back", "callback", "unhelpful", "useless",
        "escalate", "complaint", "lied", "mislead", "promised",
        "no resolution", "case closed", "ticket closed", "ignored",
    ],
    "data_privacy": [
        "privacy", "personal information", "sell my data",
        "opt out", "opt-out", "consent", "unauthorized",
        "information sharing", "third party", "marketing", "spam",
        "solicitation", "robocall", "do not call", "cpni",
        "personal data", "data shared", "data sold", "opt out of data",
    ],
    "other": [],
}

# Priority order used to resolve primary_category when multiple labels match.
# Higher priority = earlier in list. Reflects distinctiveness: billing and
# contract issues are more specific signals than generic service/support terms.
CATEGORY_PRIORITY: list[str] = [
    "billing_issue",
    "contract_dispute",
    "outage_compensation",
    "installation_issue",
    "equipment_issue",
    "network_issue",
    "service_change",
    "customer_service",
    "data_privacy",
    "other",
]


# ---------------------------------------------------------------------------
# Classification functions
# ---------------------------------------------------------------------------

def classify_complaint_multi(text: str) -> List[str]:
    """
    Return all matching category labels for a complaint string.

    Matches are determined by checking whether any keyword for a given
    category appears as a substring in the lowercased complaint text.
    Returns ["other"] if no keywords match.

    Parameters
    ----------
    text : str
        Raw or preprocessed complaint text.

    Returns
    -------
    List[str]
        Ordered list of matched category labels (order follows CATEGORY_PRIORITY).
    """
    if not isinstance(text, str):
        return ["other"]

    text_lower = text.lower()
    matched = [
        cat
        for cat in CATEGORY_PRIORITY
        if any(kw in text_lower for kw in CATEGORY_KEYWORDS.get(cat, []))
    ]
    return matched if matched else ["other"]


def get_primary_category(categories: List[str]) -> str:
    """
    Resolve the single most representative category from a multi-label list.

    Uses CATEGORY_PRIORITY to select the highest-priority matching label.
    Falls back to "other" if the input list is empty or contains no
    recognized categories.

    Parameters
    ----------
    categories : List[str]
        Output of classify_complaint_multi.

    Returns
    -------
    str
        Single category label.
    """
    for cat in CATEGORY_PRIORITY:
        if cat in categories:
            return cat
    return "other"

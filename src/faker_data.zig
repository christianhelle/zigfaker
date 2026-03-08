//! Static arrays of realistic fake data for use in fake data generation mode.

pub const first_names = [_][]const u8{
    "James",       "Mary",      "John",     "Patricia",  "Robert",
    "Jennifer",    "Michael",   "Linda",    "William",   "Barbara",
    "David",       "Elizabeth", "Richard",  "Susan",     "Joseph",
    "Jessica",     "Thomas",    "Sarah",    "Charles",   "Karen",
    "Christopher", "Lisa",      "Daniel",   "Nancy",     "Matthew",
    "Betty",       "Anthony",   "Margaret", "Mark",      "Sandra",
    "Donald",      "Ashley",    "Steven",   "Dorothy",   "Paul",
    "Kimberly",    "Andrew",    "Emily",    "Joshua",    "Donna",
    "Kenneth",     "Michelle",  "Kevin",    "Carol",     "Brian",
    "Amanda",      "George",    "Melissa",  "Timothy",   "Deborah",
    "Ryan",        "Stephanie", "Edward",   "Rebecca",   "Ronald",
    "Sharon",      "Timothy",   "Laura",    "Jason",     "Cynthia",
    "Jeffrey",     "Kathleen",  "Gary",     "Amy",       "Nicholas",
    "Angela",      "Eric",      "Shirley",  "Jonathan",  "Anna",
    "Stephen",     "Brenda",    "Larry",    "Pamela",    "Justin",
    "Emma",        "Scott",     "Nicole",   "Brandon",   "Helen",
    "Benjamin",    "Samantha",  "Samuel",   "Katherine", "Raymond",
    "Christine",   "Gregory",   "Debra",    "Frank",     "Rachel",
    "Alexander",   "Carolyn",   "Patrick",  "Janet",     "Jack",
    "Catherine",   "Dennis",    "Maria",    "Jerry",     "Heather",
};

pub const last_names = [_][]const u8{
    "Smith",     "Johnson",  "Williams", "Brown",      "Jones",
    "Garcia",    "Miller",   "Davis",    "Rodriguez",  "Martinez",
    "Hernandez", "Lopez",    "Gonzalez", "Wilson",     "Anderson",
    "Thomas",    "Taylor",   "Moore",    "Jackson",    "Martin",
    "Lee",       "Perez",    "Thompson", "White",      "Harris",
    "Sanchez",   "Clark",    "Ramirez",  "Lewis",      "Robinson",
    "Walker",    "Young",    "Allen",    "King",       "Wright",
    "Scott",     "Torres",   "Nguyen",   "Hill",       "Flores",
    "Green",     "Adams",    "Nelson",   "Baker",      "Hall",
    "Rivera",    "Campbell", "Mitchell", "Carter",     "Roberts",
    "Phillips",  "Evans",    "Turner",   "Parker",     "Collins",
    "Edwards",   "Stewart",  "Morris",   "Murphy",     "Cook",
    "Rogers",    "Morgan",   "Peterson", "Cooper",     "Reed",
    "Bailey",    "Bell",     "Gomez",    "Kelly",      "Howard",
    "Ward",      "Cox",      "Diaz",     "Richardson", "Wood",
    "Watson",    "Brooks",   "Bennett",  "Gray",       "James",
    "Reyes",     "Cruz",     "Hughes",   "Price",      "Myers",
    "Long",      "Foster",   "Sanders",  "Ross",       "Morales",
    "Powell",    "Sullivan", "Russell",  "Ortiz",      "Jenkins",
    "Gutierrez", "Perry",    "Butler",   "Barnes",     "Fisher",
};

pub const job_titles = [_][]const u8{
    "Software Engineer",            "Product Manager",
    "Data Scientist",               "UX Designer",
    "DevOps Engineer",              "Systems Architect",
    "Marketing Manager",            "Sales Representative",
    "Financial Analyst",            "Human Resources Manager",
    "Operations Manager",           "Project Manager",
    "Business Analyst",             "Quality Assurance Engineer",
    "Database Administrator",       "Network Engineer",
    "Security Analyst",             "Cloud Architect",
    "Machine Learning Engineer",    "Backend Developer",
    "Frontend Developer",           "Full Stack Developer",
    "Mobile Developer",             "Technical Writer",
    "Customer Success Manager",     "Scrum Master",
    "Chief Technology Officer",     "Chief Executive Officer",
    "Chief Operating Officer",      "Vice President of Engineering",
    "Site Reliability Engineer",    "Platform Engineer",
    "Data Engineer",                "Data Analyst",
    "Solutions Architect",          "Enterprise Architect",
    "IT Manager",                   "IT Director",
    "Software Architect",           "Engineering Manager",
    "Product Designer",             "UX Researcher",
    "Growth Hacker",                "Digital Marketing Specialist",
    "Content Strategist",           "Brand Manager",
    "Account Executive",            "Account Manager",
    "Business Development Manager", "Chief Marketing Officer",
    "Chief Financial Officer",      "General Counsel",
    "Legal Counsel",                "Compliance Officer",
    "Risk Manager",                 "Procurement Manager",
    "Supply Chain Manager",         "Logistics Coordinator",
    "Customer Support Specialist",  "Technical Support Engineer",
    "Research Scientist",           "Biomedical Engineer",
};

pub const cities = [_][]const u8{
    "New York",      "Los Angeles",   "Chicago",    "Houston",   "Phoenix",
    "Philadelphia",  "San Antonio",   "San Diego",  "Dallas",    "San Jose",
    "Austin",        "Jacksonville",  "Fort Worth", "Columbus",  "Charlotte",
    "Indianapolis",  "San Francisco", "Seattle",    "Denver",    "Nashville",
    "Oklahoma City", "El Paso",       "Washington", "Las Vegas", "Louisville",
    "Memphis",       "Portland",      "Baltimore",  "Milwaukee", "Albuquerque",
    "London",        "Paris",         "Berlin",     "Tokyo",     "Sydney",
    "Toronto",       "Dubai",         "Singapore",  "Amsterdam", "Madrid",
};

pub const countries = [_][]const u8{
    "United States", "Canada",    "United Kingdom", "Australia",
    "Germany",       "France",    "Japan",          "China",
    "India",         "Brazil",    "Mexico",         "South Korea",
    "Italy",         "Spain",     "Netherlands",    "Switzerland",
    "Sweden",        "Norway",    "Denmark",        "Finland",
    "New Zealand",   "Singapore", "South Africa",   "Argentina",
    "Chile",         "Colombia",  "Egypt",          "Nigeria",
    "Kenya",         "Turkey",
};

pub const streets = [_][]const u8{
    "Main Street",        "Oak Avenue",      "Maple Drive",     "Cedar Lane",
    "Elm Street",         "Park Boulevard",  "Washington Road", "Jefferson Way",
    "Lincoln Avenue",     "Madison Street",  "Monroe Drive",    "Adams Lane",
    "Franklin Boulevard", "Harrison Street", "Tyler Road",      "Polk Avenue",
    "Taylor Drive",       "Fillmore Lane",   "Pierce Street",   "Buchanan Way",
    "Highland Avenue",    "River Road",      "Lake Street",     "Forest Drive",
    "Sunset Boulevard",   "Sunrise Lane",    "Valley Road",     "Mountain View",
    "Ocean Avenue",       "Beach Boulevard",
};

pub const email_domains = [_][]const u8{
    "gmail.com",    "yahoo.com",      "hotmail.com", "outlook.com",
    "icloud.com",   "protonmail.com", "mail.com",    "zoho.com",
    "fastmail.com", "tutanota.com",
};

pub const company_domains = [_][]const u8{
    "acme.com",     "globex.com",    "umbrella.com", "initech.com",
    "hooli.com",    "piedpiper.com", "dunder.com",   "waystar.com",
    "veridian.com", "cyberdyne.com", "aperture.com", "weyland.com",
    "nakatomi.com", "abstergo.com",  "oscorp.com",   "stark.com",
};

pub const company_names = [_][]const u8{
    "Acme Corporation",    "Global Industries",  "Tech Solutions Inc.",
    "Digital Dynamics",    "Future Systems",     "Innovation Labs",
    "Strategic Partners",  "Premier Services",   "Elite Technologies",
    "Advanced Solutions",  "Prime Consulting",   "Next Generation Tech",
    "Alpha Enterprises",   "Beta Technologies",  "Gamma Systems",
    "Delta Solutions",     "Omega Corp",         "Apex Industries",
    "Summit Technologies", "Pinnacle Solutions",
};

pub const tlds = [_][]const u8{
    "com", "net", "org", "io", "co", "dev", "app", "tech", "info", "biz",
};

pub const hostnames_prefix = [_][]const u8{
    "api", "web", "app", "mail", "ftp", "smtp", "pop3",  "imap",
    "db",  "srv", "cdn", "ns1",  "ns2", "vpn",  "proxy", "lb",
};

pub const currency_names = [_][]const u8{
    "United States Dollar", "Euro",             "British Pound Sterling",
    "Japanese Yen",         "Canadian Dollar",  "Swiss Franc",
    "Australian Dollar",    "Chinese Yuan",     "Hong Kong Dollar",
    "Swedish Krona",        "Norwegian Krone",  "Danish Krone",
    "New Zealand Dollar",   "Singapore Dollar", "South Korean Won",
    "Indian Rupee",         "Brazilian Real",   "Mexican Peso",
    "South African Rand",   "Turkish Lira",
};

pub const currency_codes = [_][]const u8{
    "USD", "EUR", "GBP", "JPY", "CAD", "CHF", "AUD", "CNY", "HKD", "SEK",
    "NOK", "DKK", "NZD", "SGD", "KRW", "INR", "BRL", "MXN", "ZAR", "TRY",
};

pub const lorem_words = [_][]const u8{
    "lorem",        "ipsum",      "dolor",      "sit",           "amet",
    "consectetur",  "adipiscing", "elit",       "sed",           "do",
    "eiusmod",      "tempor",     "incididunt", "ut",            "labore",
    "et",           "dolore",     "magna",      "aliqua",        "enim",
    "ad",           "minim",      "veniam",     "quis",          "nostrud",
    "exercitation", "ullamco",    "laboris",    "nisi",          "aliquip",
    "ex",           "ea",         "commodo",    "consequat",     "duis",
    "aute",         "irure",      "in",         "reprehenderit", "voluptate",
    "velit",        "esse",       "cillum",     "eu",            "fugiat",
    "nulla",        "pariatur",   "excepteur",  "sint",          "occaecat",
};

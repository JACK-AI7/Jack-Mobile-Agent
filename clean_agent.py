import re
with open('lib/providers/agent_state_provider.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Remove _quickJACK Backend
text = re.sub(r'Future<String> _quickJACK Backend\(String prompt\) async \{.*?return \'\';\n  \}', '', text, flags=re.DOTALL)
# Remove _llmPost
text = re.sub(r'Future<dynamic> _llmPost\(\{.*?throw lastError \?\? Exception\(\'All JACK Backend keys and models failed\'\);\n  \}', '', text, flags=re.DOTALL)
# Remove _callGroq or _callJACK Backend
text = re.sub(r'Future<void> _callJACK Backend\(String promptText, List<String> history\) async \{.*?// always recover\n    \}\n  \}', '', text, flags=re.DOTALL)

with open('lib/providers/agent_state_provider.dart', 'w', encoding='utf-8') as f:
    f.write(text)

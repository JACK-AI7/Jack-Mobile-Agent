import re
with open('lib/services/api/jack_api_client.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the extra brace
text = text.replace("}\n  Future<void> approveExecution", "  Future<void> approveExecution")

with open('lib/services/api/jack_api_client.dart', 'w', encoding='utf-8') as f:
    f.write(text)

import json

with open('gitleaks-report.json') as f:
    data = json.load(f)

rows = ''
for item in data:
    rows += '''<tr>
        <td>{}</td>
        <td>{}</td>
        <td>{}</td>
        <td>{}</td>
        <td>{}</td>
        <td>{}</td>
        <td>{}</td>
    </tr>'''.format(
        item.get('RuleID', ''),
        item.get('Description', ''),
        item.get('File', ''),
        item.get('Line', ''),
        str(item.get('Commit', ''))[:8],
        item.get('Author', ''),
        item.get('Date', '')
    )

html = '''<!DOCTYPE html>
<html>
<head>
    <title>Gitleaks Secret Scan Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1 {{ color: #d9534f; }}
        table {{ border-collapse: collapse; width: 100%; }}
        th {{ background-color: #d9534f; color: white; padding: 10px; text-align: left; }}
        td {{ border: 1px solid #ddd; padding: 8px; word-break: break-all; }}
        tr:nth-child(even) {{ background-color: #f9f9f9; }}
        .summary {{ background: #f2dede; padding: 10px; border-radius: 4px; margin-bottom: 20px; }}
    </style>
</head>
<body>
    <h1>Gitleaks Secret Scan Report</h1>
    <div class="summary"><strong>Total Secrets Found: {}</strong></div>
    <table>
        <tr>
            <th>Rule ID</th><th>Description</th><th>File</th>
            <th>Line</th><th>Commit</th><th>Author</th><th>Date</th>
        </tr>
        {}
    </table>
</body>
</html>'''.format(len(data), rows if rows else '<tr><td colspan="7">No secrets found</td></tr>')

with open('gitleaks-report.html', 'w') as f:
    f.write(html)

print('HTML report generated: gitleaks-report.html')

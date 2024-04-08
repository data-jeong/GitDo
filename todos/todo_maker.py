import datetime

# 오늘 날짜
today = datetime.date.today().strftime("%Y-%m-%d")

# 마크다운 파일 내용
markdown_content = f"""
## 오늘 할 일 ({today})

**해야 할 일:**

- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 

"""

# 마크다운 파일 저장
with open(f"todo_{today}.md", "w") as f:
    f.write(markdown_content)

print(f"마크다운 파일 todo_{today}.md가 생성되었습니다.")

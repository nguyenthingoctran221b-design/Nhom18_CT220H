@echo off
echo Committing and force pushing changes to GitHub...
git add .
git commit -m "Da hoan thien luong xu ly cua hoa don, bep, cap nhat dashboard danh thu, xuat bao cao, phan khu bep"
git push -f
echo Done!
pause

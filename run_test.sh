if [ $# -ge 0 ]
then
    printf "Parsed output:\n" > stdout.txt
    ./main.native -print test.txt >> stdout.txt
    printf "Evaluated output:\n" >> stdout.txt
    ./main.native test.txt >> stdout.txt
else
    if [ $# -ge 1 ]
    then
        printf "Parsed output:\n" > stdout.txt
        ./main.native -print $1 >> stdout.txt
        printf "Evaluated output:\n" >> stdout.txt
        ./main.native $1 >> stdout.txt
    else
        if [ $# -ge 2 ]
        then 
            printf "Parsed output:\n" > $2
            ./main.native -print $1 >> $2
            printf "Evaluated output:\n" >> $2
            ./main.native $1 >> $2
        else
            printf "Invalid number of arguments passed."
        fi
    fi
fi
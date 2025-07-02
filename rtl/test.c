#include<stdio.h>

int main(){
	int i=1;
	int b=3;
	i+=(++i)+(i++);
	printf("%d",i);
}

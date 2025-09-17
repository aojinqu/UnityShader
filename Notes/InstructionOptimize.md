# 指令优化
以下代码都是compile shader后观察汇编指令而来的。

```C
// mad指令优化
aa=bb
aa+(-bb)
float e4 = (a+b)*(a-b);
e4 = a*a+(-b)*b;
return e4;

// 透过编译后的代码来直观的看出函数的内部执行
rsqrt(dot(a,a))*a
float e5 = normalize(a);
float4 e6 = normalize(_Value);
return e6;

// 如果abs是作为输入修饰符的话，那么它就是免费的，如果是作为输出修饰符的话就是收费的
float e7 = abs(a*b);
e7 = abs(a) * abs(b);
return e7;

// 负号可以适当地移到变量中
float e8 = -dot(a,a);
e8 = dot(-a,a);
return e8;

// 尽量把同一维度的向量进行结合运算
float1 e9 = _Value.xyz * a * b * _Value.yzw * c * d;
e9 = (_Value.xyz * _Value.yzw) * (a * b * c * d);
return float4(e9,1);
//asin/atan/acos 开销大，尽量别用
```
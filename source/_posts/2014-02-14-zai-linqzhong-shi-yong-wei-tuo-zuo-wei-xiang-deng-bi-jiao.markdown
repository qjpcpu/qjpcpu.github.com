---
layout: post
title: "在Linq中使用委托作为相等比较"
date: 2014-02-14 14:13:30 +0800
comments: true
categories: c#
---

Linq中的操作符的相等比较都使用IEqualityComparer<T>作为判断依据，常见的使用该接口的操作符有：

``` csharp
Distinct<TSource>(IEnumerable<TSource>, IEqualityComparer<TSource>)
Contains<TSource>(IEnumerable<TSource>, TSource, IEqualityComparer<TSource>)
```
                
使用该接口固然可以进行自定义的相等比较，但若对同一类型要做多种相等比较则需要继承实现IEqualityComparer<T>接口的多个子类型，这对于像我这样懒惰的程序员是很难接受的。
<!-- more -->
如果有一个Person类定义如下：

``` csharp
class Person
{
  public string Name { get; set; }
  public int Age { get; set; }
}
```
	
而有一个Person[]数组名为people，在代码中我希望这样使用Linq查询：

``` csharp
var age = people.Distinct((x, y) => x.Age == y.Age);
var nameandage = people.Distinct((x, y) => (x.Age == y.Age) && (x.Name==y.Name))
```

利用委托实现自定义的相等操作，不论是灵活性还是可读性都要好得多，下面我就要为了写成这样的代码而做做工作了。
首先，要定义一个泛型类去实现IEqualityComparer<T>接口，此外，对该类的要求是要能接受委托比较器，下面即是实现的代码：

``` csharp
public static class MyLinqOperandExtensions
{
    private class DelegateComparer<T> : IEqualityComparer<T>
    {
        private readonly Func<T, T, bool> comparator;
        public DelegateComparer(Func<T, T, bool> comparator)
        {
            this.comparator = comparator;
        }
        public bool Equals(T x, T y)
        {
            return comparator(x, y);
        }
        public int GetHashCode(T obj)
        {
            return 1;
        }
    }
}
```
    
然后，就是需要一个自定义的Distinct操作符，为了和.NET的操作符区分开来，我是用MyDistinct作为新名称：

``` csharp
public static class MyLinqOperandExtensions
{
    public static IEnumerable<T> MyDistinct<T>(this IEnumerable<T> source, Func<T, T, bool> comparator)
    {
        if (source == null)
            throw new ArgumentNullException("source");
        if (comparator == null)
            throw new ArgumentNullException("comparator");
        return source.Distinct(new DelegateComparer<T>(comparator));
    }
}
```

现在，我们就可以使用委托来使用Distinct操作了，如下示例：

``` csharp
Person[] people = new Person[] {
     new Person{Name="Jack",Age=12 },
     new Person{Name="Linq",Age=22 },
     new Person{Name="Tom",Age=22 },
     new Person{Name="Tom",Age=12 },
     new Person{Name="Jack",Age=22 }
 };
 var name = people.MyDistinct((x, y) => x.Name == y.Name);
 foreach (var n in name)
     Console.WriteLine("{0} {1}", n.Name, n.Age);
 Console.WriteLine("----------------------");
 var age = people.MyDistinct((x, y) => x.Age == y.Age);
 foreach (var n in age)
     Console.WriteLine("{0} {1}", n.Name, n.Age);
 Console.WriteLine("----------------------");
 var nameandage = people.MyDistinct((x, y) => (x.Age == y.Age) && (x.Name==y.Name));
 foreach (var n in nameandage)
  Console.WriteLine("{0} {1}", n.Name, n.Age);
```

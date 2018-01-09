#!/usr/bin/env python3
#! conding: uts-8
#!__author: CC
#!date: 2018/1/9

import sys

goods = [['iphonex',8388],['iphone',7800],['ou',3500],['xx',2000]]
#print(len(goods))
goods_id=0
salary=int(input("请输出工资:"))
shopping=[]

#我们的商品
def comm(goods_id):
    print("我们的商品.")
    while goods_id<len(goods):
        print("%s. %s,价格:%s" % (goods_id+1,goods[goods_id][0],goods[goods_id][1]))
        goods_id+=1

comm(goods_id)

def jiesuan(shopping,salary):
    print("您购买了: %s，您的余额: %s" % (shopping,salary))
    sys.exit(0)


#购买
while True:
    b=input("Please input the goods you want to buy:")
    if b=='quit':
        break
    else:
        b=int(b)
        if salary < goods[b-1][1]:
            print("余额不足.")
            print("您目前的购物车: %s,是否结算." % shopping)
            js=input(">>>(Y/N):")
            if js == 'Y' or js == 'y':
                jiesuan(shopping,salary)
            else:
                continue
        else:
            shopping.append(goods[b-1])
            salary=salary-goods[b-1][1]
            print("您购买了: %s，您的余额: %s" % (shopping, salary))
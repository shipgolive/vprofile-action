package com.visualpathit.account.utils;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.visualpathit.account.beans.Components;

@Service
public class RabbitMqUtil {
  private static Components object;
  
  public RabbitMqUtil() {
    // Default constructor for Spring dependency injection
  }
  
  @Autowired
  public static void setComponents(Components object) {
	  RabbitMqUtil.object = object;
  }
  
  public static String getRabbitMqHost() { return object.getRabbitMqHost(); }
  
  public static String getRabbitMqPort() {
    return object.getRabbitMqPort();
  }
  
  public static String getRabbitMqUser() { return object.getRabbitMqUser(); }
  
  public static String getRabbitMqPassword() {
    return object.getRabbitMqPassword();
  }
}